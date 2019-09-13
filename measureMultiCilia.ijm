// Name: measureMultiCilia.ijm Jul.2019
// Authors: Jaume Boix & Elena Rebollo, Molecular Imaging Platform IBMB, Barcelona
// Fiji version: Fiji lifeline 30 May 2017

/* Description: This macro helps measure the length of multicilia patches located along
neuroepithelial cell layers as imaged from human brain sections. Additionally, the macro 
delivers the distance of each multicilia patch respect to a reference origin, manually chosen by 
the user, e.g. the beginning of the ependymal cell layer.*/

/*Short Instructions:
Before running the macro type the XY Coordinates of the selected Origin in the code lines 22 and 23
Run the Macro. Steps will be guided:
1- Draw a line onto the desired cell layer (duplicate selection)
2- Adjust manual threshold to segment cilia
3- Split touching objects by drawing a line between them
4- Check segmentation
5- Manually correct multicilia length, represented as lines along the apicobasal axes of each 
multicilia patch
*/

// Set the x and y origin coordinates
X0=324;
Y0=773;

// Choose folder to save results
ResultsFolder=getDirectory("Select the folder to save the results");

// Previous options 
run("Colors...", "foreground=white background=black selection=yellow");
getPixelSize(unit,width,height);

// Select a ROI by drawing a line that covers several multicilia patches
run("Set Measurements...", "bounding redirect=None decimal=3");
setTool("line");
run("Line Width...", "line=200");
waitForUser("Draw a line along the selected ependymal cilia region");
run("Line to Area");

// Obtain Line coordinates and duplicate selection as a new image
Roi.getCoordinates(Xline,Yline);
dXline=Xline[3]-Xline[0];
dYline=Yline[3]-Yline[0];
X1=Xline[1]*width;
Y1=Yline[1]*width;
b=atan2(-dYline,dXline)*180/PI;
run("Copy");
run("Set Measurements...", "bounding redirect=None decimal=3");
run("Measure");
dY=getResult("Height");
dX=getResult("Width");
newImage("Cilia", "16-bit black", round(dX*1.2/width), round(dY*1.2/width), 1);
run("Paste");
run("Select None");
run("Rotate... ", "angle="+d2s(b,2)+" grid=1 interpolation=Bicubic");
run("Auto Crop");
setVoxelSize(width,height,1,unit);
run("Enhance Contrast", "saturated=0.35");

// Preprocess and segment multicilia patches  	
run("Duplicate...", "title=mask");
run("Enhance Contrast", "saturated=0.35");
run("Apply LUT");
run("8-bit");
run("Gaussian Blur...", "sigma=2");
run("Threshold...");
waitForUser("Manually set Threshold levels and hit Apply");

// Manually splitting objects, by painting a separation line
Agree=false;
while (Agree==false) {	
	roiManager("Show None");
	
	splitObjects("mask");

	selectWindow("mask");
	run("Analyze Particles...", "size=1000-Infinity pixel clear add");
	selectWindow("Cilia");
	roiManager("Show All");
	Agree=getBoolean("Do you agree with the current segmentation?");
}
count=roiManager("count");

// Preparing original image for visualization
selectWindow("mask");
run("Close");
selectWindow("Cilia");
run("RGB Color");
run("Line Width...", "line=3");
run("Colors...", "foreground=white background=black selection=red");
roiManager("Show All without labels");

// Extracting object's Feret diameter and position and overlaying a length line per object
// Measuring the distance from the objects to the origin coordinate.
distance=newArray(count);
lengthCilia=newArray(count);
run("Set Measurements...", "center bounding feret's redirect=None decimal=3");
for (i=0;i<count;i++) {
	roiManager("select",i);
	roiManager("Measure");
	XC=getResult("FeretX");
	YC=getResult("FeretY");
	distance[i]=sqrt(pow((XC+abs(X1-X0)),2)+pow((YC+abs(Y1-Y0)),2));
    AngleF=getResult("FeretAngle");
    lengthCilia[i]=getResult("Feret");	
    dXline=round((lengthCilia[i]*cos(AngleF*PI/180)));
    dYline=round((lengthCilia[i]*sin(AngleF*PI/180)));
    XL1=round(XC/width);
    YL1=round(YC/width);
    if (AngleF>90) {
    	dXline=-dXline;
    	dYline=-dYline;
    }
    XL2=round((XC+dXline)/width);
    YL2=round((YC-dYline)/width);
    makeLine(XL1,YL1,XL2,YL2);
	roiManager("update");
}

// Allowing for manual correction of the length lines  
roiManager("Show all with labels");
waitForUser("Fine tune the lines by clicking on its number and moving the line ends. Delete lines if necessary using the keyword. When finished, click OK");  
run("Set Measurements...", "area redirect=None decimal=3");

// Measuring the length of the multicilia patches
count2=roiManager("count");
for (i=0; i<count2;i++) {
    roiManager("select",i);
    roiManager("Measure");
    lengthCilia[i]=getResult("Length");	
}

// Creating Results Table
run("Table...", "name=[Cilia] width=600 height=300 menu");
print("[Cilia]", "\\Headings:"+"Object \t Distance \t Length");
for(i=0; i<count2; i++){
	print("[Cilia]", ""+(i+1)+ "\t" + distance[i] + "\t" + lengthCilia[i]);
}

// Saving Results table as .xls in the Results Folder
selectWindow("Cilia");
saveAs("Text", ResultsFolder+"results.xls");

// Function to split objects by drawing a line in between
function splitObjects(image) {
GoOn = true;
run("Line Width...", "line=2");
setTool("line");
while(GoOn) {
	selectWindow(image);
	roiManager("Show None");
	waitForUser("Paint separation lines");
	GoOn =  (selectionType()==5);
	if (GoOn == true) {
	setForegroundColor(255,255,255);
	run("Line to Area");
	run("Fill", "slice");
	run("Select None");
	}
	GoOn = getBoolean("Go on?");
}
}

