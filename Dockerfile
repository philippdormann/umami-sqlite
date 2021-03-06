FROM node:14.17.0-alpine3.13 AS build
WORKDIR /build
RUN yarn config set --home enableTelemetry 0
COPY package.json /build/
RUN yarn --production --frozen-lockfile
# Cache these modules for production
RUN cp -R node_modules/ prod_node_modules/
# Install development dependencies
RUN yarn --frozen-lockfile
COPY . /build
RUN yarn next telemetry disable
RUN yarn build

# Production image
FROM node:14.17.0-alpine3.13 AS production
WORKDIR /app

# Copy cached dependencies
COPY --from=build /build/prod_node_modules ./node_modules

# Copy generated Prisma client
COPY --from=build /build/node_modules/.prisma/ ./node_modules/.prisma/

COPY --from=build /build/package.json ./
COPY --from=build /build/.next ./.next
COPY --from=build /build/public ./public
COPY prisma ./prisma
RUN yarn prisma migrate dev
CMD ["yarn", "start"]
