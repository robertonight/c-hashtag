FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Directory.Build.props .
COPY src/ApiExample.Api/ApiExample.Api.csproj src/ApiExample.Api/
RUN dotnet restore src/ApiExample.Api/ApiExample.Api.csproj

COPY src/ApiExample.Api/ src/ApiExample.Api/
RUN dotnet publish src/ApiExample.Api/ApiExample.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "ApiExample.Api.dll"]
