# ESDPlugin
A simple plugin for the Elgato Stream Deck written in object pascal

To Build:
cd to Distribution folder
execute the command "DistributionTool -b -i com.org.software.sdPlugin -o Release"

To Install:
execute the command "Release\com.org.software.streamDeckPlugin"

Use the function GetBase64Image(FileName: String) in conjunction with GConnectionManager.SetImage to update a buttons image from a png file.
