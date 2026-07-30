var p = CelestialSphereClass.prototype;
p.getMouseAzAlt = p.getMouseAltAz = function(p)
{
   var x = this._xmouse;
   var y = this._ymouse;
   var d = Math.sqrt(x * x + y * y);
   if(d > this._c.r)
   {
      p.alt = null;
      p.az = null;
   }
   else
   {
      this.StoMH({x:x,y:y},p);
      p.alt *= 57.29577951308232;
      p.az = (360 - p.az * 57.29577951308232) % 360;
   }
};
p.getMouseDecRa = p.getMouseRaDec = function(p)
{
   var x = this._xmouse;
   var y = this._ymouse;
   var d = Math.sqrt(x * x + y * y);
   if(d > this._c.r)
   {
      p.ra = null;
      p.dec = null;
   }
   else
   {
      var hp = {};
      this.StoMH({x:x,y:y},hp);
      this.MHtoC(hp,p);
      p.ra *= 3.819718634205488;
      p.dec *= 57.29577951308232;
   }
};
p.setMouseBehavior = function(arg)
{
   if(arg == "simple drag")
   {
      this._mouseArea.useHandCursor = false;
      this._mouseArea.onRelease = this._mouseArea.onReleaseOutside = function()
      {
         delete this.onMouseMove;
      };
      this._mouseArea.onPress = this.startSimpleDragging;
   }
   else if(arg == "rotate about zenith")
   {
      this._mouseArea.useHandCursor = false;
      this._mouseArea.onRelease = this._mouseArea.onReleaseOutside = function()
      {
         delete this.onMouseMove;
      };
      this._mouseArea.onPress = this.startZenithRotation;
   }
   else if(arg == "rotate about NCP")
   {
      this._mouseArea.useHandCursor = false;
      this._mouseArea.onRelease = this._mouseArea.onReleaseOutside = function()
      {
         delete this.onMouseMove;
      };
      this._mouseArea.onPress = this.startNCPRotation;
   }
   else
   {
      delete this._mouseArea.onRelease;
      delete this._mouseArea.onReleaseOutside;
      delete this._mouseArea.onPress;
      delete this._mouseArea.onMouseMove;
   }
};
p.startSimpleDragging = function()
{
   this._dragXMouse = this._parent._xmouse;
   this._dragYMouse = this._parent._ymouse;
   this._dragTheta = this._parent._theta;
   this._dragPhi = this._parent._phi;
   this.onMouseMove = this._parent.updateSimpleDragging;
};
p.updateSimpleDragging = function()
{
   this._parent.setThetaAndPhi(57.29577951308232 * (this._dragTheta - (this._parent._xmouse - this._dragXMouse) / this._parent._c.r),57.29577951308232 * (this._dragPhi + (this._parent._ymouse - this._dragYMouse) / this._parent._c.r));
   this._parent.onMouseUpdate.call(this._parent.onMouseUpdateInstance);
};
p.startZenithRotation = function()
{
   var x = this._parent._xmouse;
   var y = this._parent._ymouse;
   if(Math.sqrt(x * x + y * y) <= this._parent._c.r)
   {
      var hp = {};
      this._parent.StoMH({x:x,y:y},hp);
      this._dragAz = hp.az;
      this.onMouseMove = this._parent.updateZenithRotation;
   }
};
p.updateZenithRotation = function()
{
   var hp = {};
   this._parent.StoMH({x:this._parent._xmouse,y:this._parent._ymouse},hp);
   this._parent.setTheta(57.29577951308232 * (this._parent._theta + (this._dragAz - hp.az)));
   this._parent.onMouseUpdate.call(this._parent.onMouseUpdateInstance);
};
p.startNCPRotation = function()
{
   var x = this._parent._xmouse;
   var y = this._parent._ymouse;
   if(Math.sqrt(x * x + y * y) <= this._parent._c.r)
   {
      var hp = {};
      var cp = {};
      this._parent.StoMH({x:x,y:y},hp);
      this._parent.MHtoC(hp,cp);
      this._dragRA = cp.ra;
      this.onMouseMove = this._parent.updateNCPRotation;
   }
};
p.updateNCPRotation = function()
{
   var hp = {};
   var cp = {};
   this._parent.StoMH({x:this._parent._xmouse,y:this._parent._ymouse},hp);
   this._parent.MHtoC(hp,cp);
   this._parent.setSiderealTime((this._parent._sTime - cp.ra + this._dragRA) * 3.819718634205488);
   this._parent.onMouseUpdate.call(this._parent.onMouseUpdateInstance);
};
p.updateMouseArea = function()
{
   var start = getTimer();
   if(!this._showUnder)
   {
      var hnp = 4;
      var step = 3.141592653589793 / hnp;
      var hstep = step / 2;
      var r = this._c.r;
      var cos = Math.cos;
      var sin = Math.sin;
      var cr = r / cos(hstep);
      var ma = this._mouseArea;
      ma.clear();
      ma.lineStyle(1,16711680,0);
      ma.moveTo(r,0);
      ma.beginFill(255,0);
      var aAngle = step;
      var cAngle = aAngle - hstep;
      var i = 0;
      while(i < hnp)
      {
         var ax = r * cos(aAngle);
         var ay = (- r) * sin(aAngle);
         var cx = cr * cos(cAngle);
         var cy = (- cr) * sin(cAngle);
         ma.curveTo(cx,cy,ax,ay);
         aAngle += step;
         cAngle += step;
         i++;
      }
      var sp = sin(Math.abs(this._phi));
      var i = 0;
      while(i < hnp)
      {
         var ax = r * cos(aAngle);
         var ay = (- sp) * r * sin(aAngle);
         var cx = cr * cos(cAngle);
         var cy = (- sp) * cr * sin(cAngle);
         ma.curveTo(cx,cy,ax,ay);
         aAngle += step;
         cAngle += step;
         i++;
      }
      ma.endFill();
   }
   else
   {
      var np = 8;
      var step = 6.283185307179586 / np;
      var hstep = step / 2;
      var r = this._c.r;
      var cos = Math.cos;
      var sin = Math.sin;
      var cr = r / cos(hstep);
      var ma = this._mouseArea;
      ma.clear();
      ma.lineStyle(1,16711680,0);
      ma.moveTo(r,0);
      ma.beginFill(255,0);
      var aAngle = step;
      var cAngle = aAngle - hstep;
      var i = 0;
      while(i < np)
      {
         var ax = r * cos(aAngle);
         var ay = (- r) * sin(aAngle);
         var cx = cr * cos(cAngle);
         var cy = (- cr) * sin(cAngle);
         ma.curveTo(cx,cy,ax,ay);
         aAngle += step;
         cAngle += step;
         i++;
      }
      ma.endFill();
   }
   if(this._traceOn)
   {
      trace("mouse area time: " + (getTimer() - start) + " ms");
   }
};
