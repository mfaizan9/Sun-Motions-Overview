var p = CelestialSphereClass.prototype;
p.setThetaAndPhi = function(newTheta, newPhi)
{
   this._theta = 0.017453292519943295 * ((newTheta % 360 + 360) % 360);
   if(newPhi > this._maxPhi)
   {
      newPhi = this._maxPhi;
   }
   else if(newPhi < this._minPhi)
   {
      newPhi = this._minPhi;
   }
   this._phi = newPhi * 0.017453292519943295;
   if(this._phi < 0)
   {
      this._iLA.swapDepths(3 * this._N - 2);
   }
   else
   {
      this._iLA.swapDepths(4 * this._N - 6);
   }
   this.doA();
   this.doB();
   this.updateMasks(true);
   this.updateMouseArea();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.setPhiAndTheta = function(newPhi, newTheta)
{
   this._theta = 0.017453292519943295 * ((newTheta % 360 + 360) % 360);
   if(newPhi > this._maxPhi)
   {
      newPhi = this._maxPhi;
   }
   else if(newPhi < this._minPhi)
   {
      newPhi = this._minPhi;
   }
   this._phi = newPhi * 0.017453292519943295;
   if(this._phi < 0)
   {
      this._iLA.swapDepths(3 * this._N - 2);
   }
   else
   {
      this._iLA.swapDepths(4 * this._N - 6);
   }
   this.doA();
   this.doB();
   this.updateMasks(true);
   this.updateMouseArea();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.getTheta = function()
{
   return 57.29577951308232 * this._theta;
};
p.setTheta = function(arg)
{
   this._theta = 0.017453292519943295 * ((arg % 360 + 360) % 360);
   this.doA();
   this.doB();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.getViewerAzimuth = function()
{
   return (360 - this.theta) % 360;
};
p.setViewerAzimuth = function(arg)
{
   this.setTheta(360 - arg);
};
p.getPhi = function()
{
   return 57.29577951308232 * this._phi;
};
p.setPhi = function(newPhi)
{
   if(newPhi > this._maxPhi)
   {
      newPhi = this._maxPhi;
   }
   else if(newPhi < this._minPhi)
   {
      newPhi = this._minPhi;
   }
   this._phi = newPhi * 0.017453292519943295;
   if(this._phi < 0)
   {
      this._iLA.swapDepths(3 * this._N - 2);
   }
   else
   {
      this._iLA.swapDepths(4 * this._N - 6);
   }
   this.doA();
   this.doB();
   this.updateMasks(true);
   this.updateMouseArea();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.getSize = function()
{
   return 2 * this._c.r;
};
p.setSize = function(arg)
{
   this._c.r = arg / 2;
   this._c.r2 = this._c.r * this._c.r;
   this.doA();
   this.doB();
   this.updateMasks();
   this.updateMouseArea();
   this.updateShading();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.getSiderealTime = function()
{
   return this._sTime * 3.819718634205488;
};
p.setSiderealTime = function(arg)
{
   this._sTime = (arg % 24 + 24) % 24 * 0.2617993877991494;
   this.doM();
   this.doB();
   this.updateObjects();
   this.updateCircles(true);
   this.updateLines(true);
};
p.getLatitude = function()
{
   return 57.29577951308232 * this._lat;
};
p.setLatitude = function(arg)
{
   if(arg > 90)
   {
      arg = 90;
   }
   else if(arg < -90)
   {
      arg = -90;
   }
   this._lat = arg * 0.017453292519943295;
   this.doM();
   this.doB();
   this.updateObjects();
   this.updateCircles(true);
   this.updateLines(true);
};
p.getShowUnder = function()
{
   return this._showUnder;
};
p.setShowUnder = function(arg)
{
   this._showUnder = Boolean(arg);
   this.updateLines();
   this.updateMasks();
   this.updateMouseArea();
   this.updateObjects();
};
p.getMinPhi = function()
{
   return this._minPhi;
};
p.setMinPhi = function(arg)
{
   if(arg > 90)
   {
      this._minPhi = 90;
   }
   else if(arg < -90)
   {
      this._minPhi = 90;
   }
   else
   {
      this._minPhi = arg;
   }
};
p.getMaxPhi = function()
{
   return this._maxPhi;
};
p.setMaxPhi = function(arg)
{
   if(arg > 90)
   {
      this._maxPhi = 90;
   }
   else if(arg < -90)
   {
      this._maxPhi = 90;
   }
   else
   {
      this._maxPhi = arg;
   }
};
p.addProperty("theta",p.getTheta,p.setTheta);
p.addProperty("phi",p.getPhi,p.setPhi);
p.addProperty("size",p.getSize,p.setSize);
p.addProperty("viewerAzimuth",p.getViewerAzimuth,p.setViewerAzimuth);
p.addProperty("viewerAltitude",p.getPhi,p.setPhi);
p.addProperty("siderealTime",p.getSiderealTime,p.setSiderealTime);
p.addProperty("latitude",p.getLatitude,p.setLatitude);
p.addProperty("showUnder",p.getShowUnder,p.setShowUnder);
p.addProperty("maxViewerAltitude",p.getMaxPhi,p.setMaxPhi);
p.addProperty("minViewerAltitude",p.getMinPhi,p.setMinPhi);
