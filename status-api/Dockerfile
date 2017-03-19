FROM microsoft/dotnet:1.1-sdk-msbuild

WORKDIR /app
COPY ./ /app
RUN dotnet restore
RUN dotnet publish -c Release -o out
 
ENV ASPNETCORE_URLS http://*:5000
EXPOSE 5000/tcp
 
ENTRYPOINT ["dotnet", "out/status-api.dll"]