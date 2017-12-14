FROM microsoft/dotnet:2.0.4-sdk-2.1.3-jessie as builder
WORKDIR /app
COPY ./ /app
RUN dotnet restore
RUN dotnet publish -c Release -o out -r linux-arm

FROM microsoft/dotnet:2.0.4-runtime-stretch-arm32v7
 
WORKDIR /app
ENV ASPNETCORE_URLS http://*:5000
EXPOSE 5000/tcp

COPY --from=builder /app .
 
ENTRYPOINT ["dotnet", "out/status-api.dll"]