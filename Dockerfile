# https://hub.docker.com/_/microsoft-dotnet
#
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS builddeps

# Install Chocolatey
ENV CHOCO_URL=https://chocolatey.org/install.ps1
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'; \
    iex ((New-Object System.Net.WebClient).DownloadString("$env:CHOCO_URL"));

# Install git
RUN choco install git.install -y

WORKDIR /source/
RUN git clone -b working https://github.com/chrisblach/UniversalAuth.git
WORKDIR /source/UniversalAuth/UniversalAuth
RUN dotnet build -c release -o /auth -f 4.5

WORKDIR /source/
RUN git clone https://github.com/Blumster/TNL.NET
WORKDIR /source/TNL.NET/TNL.NET
RUN dotnet build -c release -o /TNL.NET -f net5.0

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS builddocker
WORKDIR /source

# copy csproj and restore as distinct layers
COPY *.sln .
COPY ./Genesis.Auth/. ./Genesis.Auth/.
COPY ./Genesis.Global/. ./Genesis.Global/.
COPY ./Genesis.Sector/. ./Genesis.Sector/.
COPY ./Genesis.Shared/. ./Genesis.Shared/.
COPY ./Genesis.Utils/. ./Genesis.Utils/.
COPY ./project.json ./project.json
# COPY Genesis.Shared/*.csproj .
# RUN dotnet restore

# copy everything else and build app
WORKDIR /source
COPY ./Libraries ./Libraries
COPY --from=builddeps /auth/. ./Libraries/.
# COPY --from=builddeps /TNL.NET/. ./Libraries/.
# COPY --from=builddeps /auth/. ./Libraries/ref/.
# COPY --from=builddeps /TNL.NET/. ./Libraries/ref/.
#WORKDIR /source/Libraries
# RUN dotnet add package GenesisSharp TNL.NET -f 4.5
#RUN dir
WORKDIR /source
RUN dotnet build -c release -o /app -f 4.5 -v d
WORKDIR /app
RUN dir

# final stage/image
FROM mcr.microsoft.com/dotnet/framework/runtime:4.8
WORKDIR /app
COPY --from=build /app ./
ENTRYPOINT ["dotnet", "aspnetapp.dll"]