# These versions were picked by flyctl in June 2023
ARG ELIXIR_VERSION=1.14.5
ARG OTP_VERSION=25.3.2
ARG DEBIAN_VERSION=bullseye-20230522-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
# RUN mix deps.get --only $MIX_ENV
# At the moment (June 2023 websockex is modified so don't get it fresh)
COPY deps deps
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/corrodemo ./

#=======Corrosion===========

# just sqlite3 -- update this if Corrosion dockerfile gets updated
FROM keinos/sqlite3:3.42.0 as sqlite3

# Runtime image
#FROM debian:bullseye-slim 

COPY --from=sqlite3 /usr/bin/sqlite3 /usr/bin/sqlite3
#COPY --from=builder /usr/local/bin/nperf /usr/local/bin/nperf

# Run as "corrosion" user
RUN useradd -ms /bin/bash corrosion

COPY /entrypoint.sh /entrypoint

USER corrosion
WORKDIR /app

# need a config.toml and schemas file prepped in root of project
COPY config.toml /app/config.toml
COPY schemas /app/schemas

# Get compiled binaries from builder's cargo install directory
COPY ${CORRO_DIR}/corrosion /app/corrosion


#====Back to Phoenix stuff
ENTRYPOINT ["/entrypoint"]

USER nobody

CMD ["/app/bin/server"]

# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"
