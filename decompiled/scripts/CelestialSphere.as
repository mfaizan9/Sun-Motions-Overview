function CelestialSphereClass()
{
   this._c = new Object();
   this._aVer = -1;
   this._bVer = -1;
   this._objectFreeID = 0;
   this._objectList = [];
   this._circleFreeID = 0;
   this._circleList = [];
   this._lineFreeID = 0;
   this._lineList = [];
   this._maxPhi = 90;
   this._minPhi = -90;
   this._c.r = 150;
   this._c.r2 = this._c.r * this._c.r;
   this._showUnder = true;
   this._phi = 0.5235987755982988;
   var N = this._N;
   this.createEmptyMovieClip("_mouseArea",-1);
   this.createEmptyMovieClip("_bEL",N - 6);
   this.createEmptyMovieClip("_bOSB",N - 5);
   this.createEmptyMovieClip("_bOSA",N - 4);
   this.createEmptyMovieClip("_bOSF",N - 3);
   this.createEmptyMovieClip("_bF",N - 2);
   this.createEmptyMovieClip("_bC",N - 1);
   this.createEmptyMovieClip("_bISB",2 * N - 4);
   this.createEmptyMovieClip("_bISA",2 * N - 3);
   this.createEmptyMovieClip("_bISF",2 * N - 2);
   this.createEmptyMovieClip("_iLB",3 * N - 2);
   this.createEmptyMovieClip("_hP",3 * N - 1);
   this.createEmptyMovieClip("_iLA",4 * N - 6);
   this.createEmptyMovieClip("_fISB",4 * N - 5);
   this.createEmptyMovieClip("_fISA",4 * N - 4);
   this.createEmptyMovieClip("_fISF",4 * N - 3);
   this.createEmptyMovieClip("_fF",4 * N - 2);
   this.createEmptyMovieClip("_fC",4 * N - 1);
   this.createEmptyMovieClip("_fOSB",5 * N - 4);
   this.createEmptyMovieClip("_fOSA",5 * N - 3);
   this.createEmptyMovieClip("_fOSF",5 * N - 2);
   this.createEmptyMovieClip("_fEL",6 * N - 1);
   this._hP.createEmptyMovieClip("_below",0);
   this._hP.createEmptyMovieClip("_above",1);
   this.setThetaAndPhi(90,30);
   this.setLatitude(41);
   this.setSiderealTime(0);
   this.createMasks();
   this.addHorizonPlaneClip("CSAboveHorizonPlane","aboveHorizonPlane","above",0);
   this.addHorizonPlaneClip("CSBelowHorizonPlane","belowHorizonPlane","below",0);
   this.addShadingClip("CSGradientDisk","celestialBowl","front","inner","both",{innerAlpha:0,innerColor:16777215,outerAlpha:20,outerColor:0});
   this.setMouseBehavior("simple drag");
   this.onMouseUpdateInstance = this._parent;
   this.sortObjects = true;
   this.update();
}
var p = CelestialSphereClass.prototype = new MovieClip();
Object.registerClass("CelestialSphere",CelestialSphereClass);
p._traceOn = false;
p._N = 10000;
p.update = function()
{
   this.updateMasks(true);
   this.updateShading();
   this.updateHorizonPlane();
   this.updateObjects();
   this.updateCircles();
   this.updateLines();
};
p.mod = function(n, m)
{
   if(n < 0)
   {
      return n % m + m;
   }
   return n % m;
};
