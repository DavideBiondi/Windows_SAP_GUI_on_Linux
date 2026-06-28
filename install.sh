#!/bin/bash
#Creating the working folder
mkdir -p ~/Windows_SAP_GUI_on_Linux
mkdir -p ~/Windows_SAP_GUI_on_Linux/sapwine
mkdir -p ~/Windows_SAP_GUI_on_Linux/helper_files
mkdir -p ~/Windows_SAP_GUI_on_Linux/sapgui-extracted

cd ~/Windows_SAP_GUI_on_Linux/sapwine

#Updating and imposing the architecture
sudo apt update
sudo dpkg --add-architecture i386
# -y option can be found in man pages for apt-get, it assumes "yes" without prompting the user for confirmation
sudo apt install -y wine32 wine64
sudo apt install -y winetricks
sudo apt install -y wine-gecko
sudo apt install -y wine-mono cabextract
#Version check (it will impose the most updated version as the default one) avoiding double entries
grep -qxF 'export PATH="/opt/wine-stable/bin:$PATH"' ~/.bashrc || \
echo 'export PATH="/opt/wine-stable/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
wine --version
#Set Windows version to: Windows 10, apply and close
echo "Configuring Wine... Set Windows version to Windows 10, then close winecfg"
export WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine
export WINEARCH=win32
winecfg
#Install Wine dependencies
echo "Installing Wine dependencies (this may take 20-30 minutes)..."
# Even with the previous export, is a best practice to always set the WINEPREFIX variable every time you use wine or winetricks
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks corefonts vcrun2008 vcrun2010 vcrun2013 vcrun2015 msls31 riched20 riched30 gdiplus msxml6
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks dotnet48
if [[ $? -ne 0 ]]; then
	echo "Error in installing dotnet48, trying with a lower version"
	WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks dotnet472
	if [[ $? -ne 0 ]]; then
	echo "Error in installing dotnet472"
	fi
fi
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks ie8 dotnet40        # for BEx compatibility
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks vcrun6 vcrun6sp6
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks wsh57 wsh56
# COM/OLE components and more
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks oleaut32 comctl32 vb6run vbscript # for vbscript.dll

WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks comctl32ocx comdlg32ocx vb5run
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks wmp9 # for msdxm.ocx
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine winetricks msscript
echo "Searching for msdxm.ocx after installing wmp9"
find ~/Windows_SAP_GUI_on_Linux/sapwine -iname "msdxm.ocx"
cd ~/Windows_SAP_GUI_on_Linux/helper_files
# Download .exe helper files
echo "Downloading .exe helper files..."
#curl -O -J "https://download.microsoft.com/download/8/4/a/84a35bf1-dafe-4ae8-82af-ad2ae20b6b14/directx_Jun2010_redist.exe"
curl -L "https://aka.ms/vc14/vc_redist.x86.exe" -o vcredist_x86_2019.exe # Visual C++ 2019
curl "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe" -o vcredist_x86_2012.exe # Visual C++ 2012
curl -L "https://aka.ms/vs/16/release/14.29.30133/VC_Redist.x86.exe" -o vcredist_x86_2015.exe # Visual C++ 2015-2019
curl -O -J "https://download.microsoft.com/download/3/a/5/3a5925ac-e779-4b1c-bb01-af67dc2f96fc/VisualBasic6-KB896559-v1-ENU.exe" # for mscomctl.ocx and comctl32.ocx
#curl -O -J "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"
#curl -L -O -J "https://aka.ms/vs/17/release/vc_redist.x86.exe"

# Download ocx files
curl -O -J "https://www.bioinformatics.org/snp-tools-excel/comdlg32.ocx"

# Extract the necessary ocx files
echo "Extract the necessary ocx files..."
7z x VisualBasic6-KB896559-v1-ENU.exe mscomctl.ocx comctl32.ocx

cd ..
# Visual C++ redistributables (from helper_files)
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine helper_files/vcredist_x86_2019.exe   # Visual C++ 2019
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine helper_files/vcredist_x86_2015.exe   # Visual C++ 2015
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine helper_files/vcredist_x86_2012.exe   # Visual C++ 2012

#Download SAP GUI for Windows from SAP official site (version 7.60)
cd sapgui-extracted
# Prompt to user to know if he/she downloaded the SAP_GUI_7.60.exe file in the  sapgui_extracted/ folder or move it there after downloading
while true; do
    read -p "Did you put SAP_GUI_7.60.exe file in the  sapgui_extracted/ folder?" yesno
    case $yesno in
        [Yy]* ) 
            echo "Proceeding with installation"
            break
        ;;
        [Nn]* ) 
            echo "You answered no, exiting"
            exit
        ;;
        * ) echo "Answer either yes or no!";;
    esac
done
cabextract SAP_GUI_7.60.exe
cd ..
echo "Now you will have to put ocx and dll files in the helper_files/ folder"
# Initialize Wine prefix
WINEARCH=win32 WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wineboot
while true; do
    read -p $'Did you put the following files in the helper_files/ folder?\n
    \tvbscript.dll\n\tcomctl32.dll\n\tcomdlg32.dll\n\toleaut32.dll' yesno
    case $yesno in
        [Yy]* ) 
            echo "Proceeding with tests implementation"
            break
        ;;
        [Nn]* ) 
            echo "You answered no, exiting"
            exit
        ;;
        * ) echo "Answer either yes or no!";;
    esac
done
# DLLs and ocx management
# Copy manual DLLs (add -f to force overwriting)
cp -f helper_files/vbscript.dll ./sapwine/drive_c/windows/system32/
cp -f helper_files/comctl32.dll ./sapwine/drive_c/windows/system32/
cp -f helper_files/comdlg32.dll ./sapwine/drive_c/windows/system32/
cp -f helper_files/oleaut32.dll ./sapwine/drive_c/windows/system32/

# --- TEST VBS ---
echo 'MsgBox "VBScript is working!"' > vbscript_test.vbs
echo 'MsgBox "comctl32.dll is present!"' > comctl32_test.vbs
echo 'MsgBox "comdlg32.dll is present!"' > comdlg32_test.vbs
echo 'MsgBox "oleaut32.dll is present!"' > oleaut32_test.vbs
echo -e ' testactivex.vbs\nDim obj\nSet obj = CreateObject("SAPI.SpVoice")\nobj.Speak "COM works!"' > testactivex.vbs
# Move the tests
mv vbscript_test.vbs ./sapwine/drive_c/
mv comctl32_test.vbs ./sapwine/drive_c/
mv comdlg32_test.vbs ./sapwine/drive_c/
mv oleaut32_test.vbs ./sapwine/drive_c/
mv testactivex.vbs ./sapwine/drive_c/
# Execute the tests and register the dlls
echo 'Executing the tests'
for dll in vbscript comctl32 comdlg32 oleaut32; do
    WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\${dll}_test.vbs
    if [ $? -eq 0 ]; then
        echo "[OK] ${dll} test passed — attempting regsvr32"
        WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 ${dll}.dll
    else
        echo "[ERROR] ${dll} test failed — skipping registration"
    fi
done
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\testactivex.vbs
# Register key DLLs
echo 'Registering key dlls'
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 "C:\\Program Files\\SAP\\FrontEnd\\SapGui\\SAPsbar.OCX"
#WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 "C:\\Program Files\\SAP\\Business Explorer\\BI\\BExApi.dll"
#WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 "C:\\Program Files\\SAP\\Business Explorer\\BI\\BExAddin.dll"

# ---  ocx files handling ---
cp -f helper_files/msdxm.ocx ./sapwine/drive_c/windows/system32/
echo 'Set x = CreateObject("WMPlayer.OCX") : MsgBox "msdxm.ocx is working!"' > msdxm_test.vbs
cp msdxm_test.vbs ./sapwine/drive_c/
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\msdxm_test.vbs
if [ $? -eq 0 ]; then
	echo "[OK] msdxm test passed — attempting registration"
    WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 msdxm.ocx
else
	echo "[ERROR] msdxm test failed — skipping registration"
fi
#comctl32
cp -f helper_files/comctl32.ocx ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/windows/system32/
echo 'Set x = CreateObject("WMPlayer.OCX") : MsgBox "comctl32.ocx is working!"' > comctl32_test.vbs
cp comctl32_test.vbs ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\comctl32_test.vbs
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 comctl32.ocx
#comdlg32
cp -f helper_files/comdlg32.ocx ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/windows/system32/
echo 'Set x = CreateObject("WMPlayer.OCX") : MsgBox "comdlg32.ocx is working!"' > comdlg32_test.vbs
cp comdlg32_test.vbs ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\comdlg32_test.vbs
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 comdlg32.ocx
#mscomctl
cp -f helper_files/mscomctl.ocx ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/windows/system32/
echo 'Set x = CreateObject("WMPlayer.OCX") : MsgBox "mscomctl.ocx is working!"' > mscomctl_test.vbs
cp mscomctl_test.vbs ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\mscomctl_test.vbs
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 mscomctl.ocx
#msscript
cp -f helper_files/msscript/msscript.ocx ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/windows/system32/
echo 'Set x = CreateObject("MSScriptControl.ScriptControl") : MsgBox "msscript.ocx is working!"' > msscript_test.vbs
cp msscript_test.vbs ~/Windows_SAP_GUI_on_Linux/sapwine/drive_c/
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine wscript.exe C:\\msscript_test.vbs
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine regsvr32 msscript.ocx

#SAP GUI Installation
cd ~/Windows_SAP_GUI_on_Linux/sapgui-extracted
#From sapgui-extracted folder SapGuiSetup.exe is launched
WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine ./SapGuiSetup.exe

#Fix SAP Logon broken shortcut
echo "Fixing SAP Logon desktop shortcut..."
DESKTOP_FILE="$HOME/.local/share/applications/wine/Programs/SAP Front End/SAP Logon.desktop"
if [ -f "$DESKTOP_FILE" ]; then
	echo "The file has been found"
	#Using awk as a text editor
	awk -v home="$HOME" 'BEGIN{print "[Desktop Entry]\n\
Name=SAP Logon\n\
Exec=env WINEPREFIX="home"/Windows_SAP_GUI_on_Linux/sapwine wine \"C:\\\\Program Files\\\\SAP\\\\FrontEnd\\\\SAPgui\\\\saplogon.exe\"\n\
Type=Application\n\
StartupNotify=true\n\
Path="home"/Windows_SAP_GUI_on_Linux/sapwine/dosdevices/c:/Program Files/SAP/FrontEnd/SAPgui\n\
Icon=11CB_saplogon.0\n\
StartupWMClass=saplogon.exe"}' > $DESKTOP_FILE
	echo "Desktop shortcut fixed!"
else
	echo "Desktop shortcut not found at: $DESKTOP_FILE"
	echo "Launch the GUI from the terminal by using:"
	echo "WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine \"C:\\\\Program Files\\\\SAP\\\\FrontEnd\\\\SAPgui\\\\saplogon.exe\""
fi
echo "Installation completed!"
#---------------------------------------------------------------------------------------------------------------------------
#Uncomment in order to launch the SAP GUI for Windows on Wine
#WINEPREFIX=~/Windows_SAP_GUI_on_Linux/sapwine wine "C:\\Program Files\\SAP\\FrontEnd\\SAPgui\\saplogon.exe"


