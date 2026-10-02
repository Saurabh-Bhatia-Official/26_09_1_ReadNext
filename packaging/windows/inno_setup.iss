; =====================================================================
; Inno Setup Script for ReadNext — Advanced PDF Viewer & Utility Suite
; Generates a professional Windows .exe installer with standard wizard:
; Welcome -> Directory -> Shortcut -> Install -> Finish (Launch App)
; =====================================================================

#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif

#define MyAppName "ReadNext"
#define MyAppPublisher "Complex Innovators"
#define MyAppURL "https://github.com/complexinnovators/readnext"
#define MyAppExeName "read_next.exe"
#define MyAppSourceDir "..\..\build\windows\x64\runner\Release"
#define MyAppIcon "..\..\windows\runner\resources\app_icon.ico"

[Setup]
; Unique GUID for ReadNext application
AppId={{D8C94E5A-6712-4C10-9F1B-4A73E678B31A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename=ReadNext-Setup-v{#MyAppVersion}
SetupIconFile={#MyAppIcon}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Include all files built by Flutter release
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu Shortcut
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
; Desktop Shortcut (Optional task)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Launch program checkbox on finish screen
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
