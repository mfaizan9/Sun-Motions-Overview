var p = CelestialSphereClass.prototype;
p.addHorizonPlaneClip = function(linkageName, name, side, depth, initObject)
{
   if(side == "below")
   {
      var mc = this._hP._below;
   }
   else
   {
      var mc = this._hP._above;
   }
   if(typeof depth != "number")
   {
      var depth = 0;
      while(mc["_" + depth] != undefined)
      {
         depth++;
      }
   }
   if(depth < 0)
   {
      var intName = "__" + Math.abs(depth);
   }
   else
   {
      var intName = "_" + depth;
   }
   this[name] = mc.attachMovie(linkageName,intName,depth,initObject);
   return this[name];
};
p.updateHorizonPlane = function()
{
   this._hp._xscale = this._c.r;
   this._hp._yscale = this._c.r * Math.sin(this._phi);
   if(this._phi > 0)
   {
      this._hp._below._visible = false;
      this._hp._above._visible = true;
      this._hp._above._rotation = 180 + this._theta * 57.29577951308232;
   }
   else
   {
      this._hp._above._visible = false;
      this._hp._below._visible = true;
      this._hp._below._rotation = 180 + this._theta * 57.29577951308232;
   }
};
p.getShowHPlane = function()
{
   return this._hp._visible;
};
p.setShowHPlane = function(arg)
{
   arg = Boolean(arg);
   if(arg && !this._hp._visible)
   {
      this.updateHorizonPlane();
   }
   this._hp._visible = arg;
};
p.addProperty("showHorizonPlane",p.getShowHPlane,p.setShowHPlane);
