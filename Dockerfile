# syntax=docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=20.11.0
FROM node:${NODE_VERSION}-alpine as base

################################# 
# set version label
ARG BUILD_DATE
ARG VERSION
ARG MSTREAM_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"
##################################

# app lives here
WORKDIR /app

# Set production environment
ENV NODE_ENV="production"

# Throw-away build stage to reduce size of final image
FROM base as build

# Install node
RUN apk add --no-cache --upgrade nodejs openssl && \
  apk add --no-cache --upgrade --virtual=build-dependencies npm

# Install node modules
COPY --link package-lock.json package.json ./
RUN npm ci --only=prod

# copy sources
COPY --link . .

# remove cached files to reduce size
RUN apk del --purge build-dependencies && \
  rm -rf $HOME/.cache $HOME/.npm /tmp/* /tmp/.npm

# Final stage for app image
FROM base

# Copy built application
COPY --from=build /app /app

# Setup sqlite3 on a separate volume
RUN mkdir -p /data
VOLUME /data
EXPOSE 3000

# currently not using CMD [ "npm", "run", "start" ]
CMD [ "node", "cli-boot-wrapper.js" ]