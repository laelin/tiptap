# build
FROM node:20-alpine AS build
WORKDIR /app
# pnpm via Corepack
RUN corepack enable
COPY package.json pnpm-lock.yaml* ./
COPY turbo.json ./
COPY packages ./packages
COPY packages-deprecated ./packages-deprecated
COPY demos ./demos
COPY patches ./patches
COPY tsconfig.* ./
COPY .eslintrc.* ./
RUN pnpm install --no-frozen-lockfile
# full monorepo build, then demos build
RUN pnpm turbo run build
RUN pnpm --prefix demos run build:demos

# serve demos build
FROM nginx:alpine
COPY --from=build /app/demos/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
