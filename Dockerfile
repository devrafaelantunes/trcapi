FROM hexpm/elixir:1.13.4-erlang-24.2-alpine-3.16.0 as build

# install build dependencies
RUN apk add --no-cache build-base git curl wget

WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# Fetch and compile dependencies
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

COPY config/config.exs config/prod.exs config/
COPY lib ./lib/
COPY priv ./priv/
COPY rel ./rel/

# compile first to generate co-located js hooks from surface
RUN mix compile
RUN mix release

FROM alpine:3.16.0 as app
RUN apk add --update --no-cache libstdc++ openssl ncurses-libs git

EXPOSE 4000

ENV MIX_ENV=prod
ENV USER=trc

# Creates an unprivileged user to be used exclusively to run the Phoenix app
RUN \
    addgroup \
    -g 1000 \
    -S "${USER}" \
    && adduser \
    -s /bin/sh \
    -u 1000 \
    -G "${USER}" \
    -h "/opt/${USER}" \
    -D "${USER}" \
    && su "${USER}"

COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/trc "/opt/${USER}"

COPY rel/entrypoint.sh /opt/trc/entrypoint.sh
COPY datasets /opt/datasets
RUN chmod +x /opt/trc/entrypoint.sh
RUN chown ${USER}:${USER} /opt/trc/entrypoint.sh
RUN chown -R ${USER}:${USER} /opt/datasets

USER "${USER}"
WORKDIR "/opt/${USER}"

CMD ["/opt/trc/entrypoint.sh"]
##CMD ["start"]