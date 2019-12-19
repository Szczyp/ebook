FROM mcr.microsoft.com/dotnet/core/sdk:2.2-alpine AS build

WORKDIR /opt/scribe

COPY scribe/scribe.fsproj ./

RUN dotnet restore

COPY scribe/Program.fs ./

RUN dotnet publish -c Release -r linux-musl-x64 -o out --self-contained true /p:PublishTrimmed=true

FROM mcr.microsoft.com/dotnet/core/runtime-deps:2.2-alpine AS runtime

WORKDIR /opt/scribe

COPY --from=build /opt/scribe/out ./

ENTRYPOINT ["./scribe"]