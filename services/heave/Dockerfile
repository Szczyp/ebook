FROM mcr.microsoft.com/dotnet/core/sdk:2.2-alpine AS build

WORKDIR /opt/heave

COPY heave/heave.csproj ./

RUN dotnet restore

COPY heave/Program.cs ./

RUN dotnet publish -c Release -r linux-musl-x64 -o out --self-contained true /p:PublishTrimmed=true

FROM mcr.microsoft.com/dotnet/core/runtime-deps:2.2-alpine AS runtime

WORKDIR /opt/heave

COPY --from=build /opt/heave/out ./

ENTRYPOINT ["./heave"]