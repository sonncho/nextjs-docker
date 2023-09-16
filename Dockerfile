# node:18-alpine기반으로 이미지 생성
FROM node:18-alpine AS base

# 필요할때만 dependencies를 설치
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# 사용하는 패키지에 맞게 Dependencies 설치
COPY package.json yarn.lock ./
# yarn만 사용하는경우 RUN yarn --frozen-lockfile만 작성해줘도됨
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# 이미지 용량 최소화를 위해 빌드를 위한 두번째 레이어 만들기
# 도커이미지는 레이어를 축적해서 만들어지는데 이 떄 이전 이미지의 레이어와 현재 빌드하는 이미지의 레이어가 같다면 재사용한다.(캐싱)
# 즉 역할별 레이어를 세분화해서 바뀌지 않는 부분은 재사용하게 해서 빌드 시 사용되는 리소스 최소화
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next에서 원격으로 데이터 수집을 못하게 telemetry서버를 꺼준다.
ENV NEXT_TELEMETRY_DISABLED 1

# 빌드하기
RUN yarn build

# 이미지생성을 위한 세번쨰 레이어 생성
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

ENV NEXT_TELEMETRY_DISABLED 1

# sudo없이 로컬에서 이미지를 컨테이너에서 실행할 수 있도록 add group, add user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# docker에서 public같은 정적폴더는 가져올지 못하므로 몽땅 복사
COPY --from=builder /app/public ./public

# 사용 렌더 캐시에 대한 올바른 사용 권한 설정
RUN mkdir .next
RUN chown nextjs:nodejs .next

# 이미지 사이즈 줄이기
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]