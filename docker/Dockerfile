FROM microsoft/windowsservercore

RUN powershell.exe "Install-PackageProvider nuget -Force"
RUN powershell.exe  "Install-Module SqlServer -Force -AllowClobber"
RUN powershell.exe  "Install-Module AzureRM -Force -AllowClobber"

ADD .\\dependencies\\BenchCraft-All.msi C:\\Users\\ContainerAdministrator\\BenchCraft-All.msi
ADD .\\dependencies\\sqlncli.msi C:\\Users\\ContainerAdministrator\\sqlncli.msi
ADD .\\dependencies\\msodbcsql.msi C:\\Users\\ContainerAdministrator\\msodbcsql.msi
ADD .\\dependencies\\MsSqlCmdLnUtils.msi C:\\Users\\ContainerAdministrator\\MsSqlCmdLnUtils.msi

RUN C:\\Users\\ContainerAdministrator\\BenchCraft-All.msi TARGETDIR="C:\BenchCraft" /qn
RUN msiexec /qn /i C:\Users\ContainerAdministrator\msodbcsql.msi IACCEPTMSODBCSQLLICENSETERMS=YES ADDLOCAL=ALL
RUN msiexec /qn /i C:\Users\ContainerAdministrator\sqlncli.msi IACCEPTSQLNCLILICENSETERMS=YES ADDLOCAL=ALL
RUN msiexec /qn /i C:\Users\ContainerAdministrator\MsSqlCmdLnUtils.msi IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES ADDLOCAL=ALL

ADD .\\benchcraft_profiles C:/Users/ContainerAdministrator/benchcraft_profiles/
ADD .\\scripts\ C:/Users/ContainerAdministrator/scripts/

# Set the working directory to HOME C:/Users/ContainerAdministrator/
WORKDIR C:/Users/ContainerAdministrator/