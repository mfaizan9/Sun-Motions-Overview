function stepOneChanged()
{
   if(checkBox1.getValue() == true)
   {
      sphere.addLine("ncpAxis",{thickness:3,color:7711231,alpha:100},{x:0,y:0,z:0,system:"celestial"},{x:0,y:0,z:1.2,system:"celestial"});
      sphere.addLine("scpAxis",{thickness:3,color:7711231,alpha:100},{x:0,y:0,z:0,system:"celestial"},{x:0,y:0,z:-1.2,system:"celestial"});
      addDeclinationText(4,"NCP",0,85,0.5);
      addDeclinationText(5,"NCP",12,85,0.5);
      addDeclinationText(6,"SCP",0,-85,0.5);
      addDeclinationText(7,"SCP",12,-85,0.5);
      sphere.updateLines();
   }
   else
   {
      sphere.ncpAxis.remove();
      sphere.scpAxis.remove();
      setDeclinationTextVisibility(4,false);
      setDeclinationTextVisibility(5,false);
      setDeclinationTextVisibility(6,false);
      setDeclinationTextVisibility(7,false);
   }
   sphere.updateObjects();
}
function stepTwoChanged()
{
   if(checkBox2.getValue() == true)
   {
      sphere.addCircle("celestialEquator",{thickness:3,color:16769909,alpha:100},{ra:0,dec:0,tilt:0});
      sphere.celestialEquator.update();
      addDeclinationText(100,"Celestial Equator",0,0.7,0.5);
      setDeclinationTextVisibility(101,false);
   }
   else
   {
      sphere.celestialEquator.remove();
      setDeclinationTextVisibility(100,false);
      if(checkBox3.getValue() == true)
      {
         setDeclinationTextVisibility(101,true);
      }
   }
   sphere.updateObjects();
}
function stepThreeChanged()
{
   if(checkBox3.getValue() == true)
   {
      sphere.addCircle("equinoxPath",{thickness:3,color:16711680,alpha:100},{ra:0,dec:0,tilt:0});
      addDeclinationText(101,"Equinox Path",0,0.7,0.5);
      setDeclinationTextVisibility(100,false);
      sphere.equinoxPath.update();
   }
   else
   {
      sphere.equinoxPath.remove();
      setDeclinationTextVisibility(101,false);
      if(checkBox2.getValue() == true)
      {
         setDeclinationTextVisibility(100,true);
      }
   }
   sphere.updateObjects();
}
function stepFourChanged()
{
   if(checkBox4.getValue() == true)
   {
      sphere.addCircle("sSolsticePath",{thickness:3,color:16711680,alpha:100},{ra:0,dec:23.5,tilt:0});
      sphere.addCircle("wSolsticePath",{thickness:3,color:16711680,alpha:100},{ra:0,dec:-23.5,tilt:0});
      sphere.sSolsticePath.update();
      sphere.wSolsticePath.update();
      addDeclinationText(102,"Summer Solstice Path",0,23.5,0.5);
      addDeclinationText(103,"Winter Solstice Path",0,-23.5,0.5);
   }
   else
   {
      sphere.sSolsticePath.remove();
      sphere.wSolsticePath.remove();
      setDeclinationTextVisibility(102,false);
      setDeclinationTextVisibility(103,false);
   }
   sphere.updateObjects();
}
function changeLatitude(arg)
{
   sphere.latitude = arg;
}
function removeDeclinationText(id)
{
   var string = decTextStringsArray[id];
   var i = 0;
   while(i < string.length)
   {
      string[i].remove();
      i++;
   }
   delete decTextStringsArray[id];
}
function setDeclinationTextVisibility(id, isVisible)
{
   trace(isVisible);
   var string = decTextStringsArray[id];
   var i = 0;
   while(i < string.length)
   {
      string[i].visible = isVisible;
      i++;
   }
}
function addDeclinationText(id, str, ra, dec, gap)
{
   var newDecTextString = [];
   var fontSource = "Verdana Letter";
   var r = Math.cos(dec * 0.017453292519943295) * (sphere.size / 2);
   var spacingTest = attachMovie(fontSource,"testLetter",24682);
   var format = spacingTest.letterField.getTextFormat();
   var spacingAngle = gap * format.getTextExtent(" ").width / r;
   spacingTest.removeMovieClip();
   var letters = str.split("");
   var letterRAs = [];
   var cursorAngle = 0;
   var i = 0;
   while(i < letters.length)
   {
      var letterAngle = format.getTextExtent(letters[i]).width / r;
      letterRAs[i] = 3.819718634205488 * (cursorAngle + letterAngle / 2);
      cursorAngle = cursorAngle + letterAngle + spacingAngle;
      i++;
   }
   cursorAngle -= spacingAngle;
   var offset = 3.819718634205488 * (cursorAngle / 2);
   var i = 0;
   while(i < letters.length)
   {
      if(sphere.latitude > 0)
      {
         var tmp = sphere.addObject(fontSource,"_dt" + decTextIndex,{dec:dec,ra:ra + letterRAs[i] - offset},{letter:letters[i]});
         newDecTextString.push(tmp);
         tmp.setOrientationType("absolute",{dec:dec,ra:ra + letterRAs[i] - offset},{dec:90,ra:ra + leterrsRAs[i] - offset});
      }
      else
      {
         var tmp = sphere.addObject(fontSource,"_dt" + decTextIndex,{dec:dec,ra:ra - letterRAs[i] + offset},{letter:letters[i]});
         newDecTextString.push(tmp);
         tmp.setOrientationType("absolute",{dec:dec,ra:ra - letterRAs[i] + offset},{dec:-90,ra:ra - leterrsRAs[i] + offset});
      }
      decTextIndex++;
      i++;
   }
   decTextStringsArray[id] = newDecTextString;
}
function setDeclinationTextVisibility(id, isVisible)
{
   var string = decTextStringsArray[id];
   var i = 0;
   while(i < string.length)
   {
      trace(string[i]);
      string[i].visible = isVisible;
      i++;
   }
}
latitudeSlider.setStyleProperty("textColor",16777215);
latitudeSlider.setStyleProperty("face",16777215);
latitudeSlider.setStyleProperty("textBold",true);
latitudeSlider.setStyleProperty("textSize",14);
checkBox1.setStyleProperty("textColor",16777215);
checkBox1.setStyleProperty("face",16777215);
checkBox1.setStyleProperty("textBold",true);
checkBox1.setStyleProperty("textSize",14);
checkBox2.setStyleProperty("textColor",16777215);
checkBox2.setStyleProperty("face",16777215);
checkBox2.setStyleProperty("textBold",true);
checkBox2.setStyleProperty("textSize",14);
checkBox3.setStyleProperty("textColor",16777215);
checkBox3.setStyleProperty("face",16777215);
checkBox3.setStyleProperty("textBold",true);
checkBox3.setStyleProperty("textSize",14);
checkBox4.setStyleProperty("textColor",16777215);
checkBox4.setStyleProperty("face",16777215);
checkBox4.setStyleProperty("textBold",true);
checkBox4.setStyleProperty("textSize",14);
sphere.viewerAzimuth = 200;
sphere.viewerAltitude = 40;
sphere.size = 250;
sphere.sortObjects = false;
sphere.addObject("Stickman","stickman",{x:0,y:0,z:0,system:"horizon"});
sphere.stickman.setOrientationType("skewed",{alt:90,az:0});
sphere.addCircle("meridianCircle1",{thickness:1,color:16777215,alpha:20},{ra:0,dec:0,tilt:90});
sphere.addCircle("meridianCircle2",{thickness:1,color:16777215,alpha:20},{ra:6,dec:0,tilt:90});
sphere.meridianCircle1.update();
sphere.meridianCircle2.update();
sphere.addShadingClip("sphere outside","outsideOfSphere","front","inner","both");
sphere.addShadingClip("sphere outside2","outsideOfSphere2","front","outer","below");
sphere.addHorizonPlaneClip("direction labels dark","belowLabels","below");
sphere.addHorizonPlaneClip("direction labels light","aboveLabels","above");
sphere.setLatitude(41);
decTextIndex = 0;
decTextStringsArray = [];
sphere.updateObjects();
sphere.updateObjects();
stop();
