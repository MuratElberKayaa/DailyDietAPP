FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Tüm csproj dosyalarını kopyala ve restore et
COPY DailyDietAPI.csproj ./DailyDietAPI/
COPY ../DailyDietAPI.Model/DailyDietAPI.Model.csproj ./DailyDietAPI.Model/
COPY ../DailyDietAPI.Persistence/DailyDietAPI.Persistence.csproj ./DailyDietAPI.Persistence/
COPY ../DailyDietAPI.Services/DailyDietAPI.Services.csproj ./DailyDietAPI.Services/
WORKDIR /src/DailyDietAPI
RUN dotnet restore

# Tüm kaynak kodunu kopyala
WORKDIR /src
COPY . ./DailyDietAPI
COPY ../DailyDietAPI.Model ./DailyDietAPI.Model
COPY ../DailyDietAPI.Persistence ./DailyDietAPI.Persistence
COPY ../DailyDietAPI.Services ./DailyDietAPI.Services

# Publish
WORKDIR /src/DailyDietAPI
RUN dotnet publish -c Release -o /app/publish

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 5000
EXPOSE 5001

ENV ASPNETCORE_URLS="http://+:5000;https://+:5001"
ENV ASPNETCORE_ENVIRONMENT="Production"

ENTRYPOINT ["dotnet", "DailyDietAPI.dll"] 