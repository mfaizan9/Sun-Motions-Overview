function CSCirclesClass(parent, name, id, depth)
{
   this._parent = parent;
   this._name = name;
   this._id = id;
   this._depth = depth;
   this._c = {};
   this._wVer = -1;
   this._gS = 0;
   this._gE = 0;
   this._beta = 0;
   this._tilt = 0;
   this._lambda = 0;
   this._sys = 0;
   this._visible = true;
   this._useMouseFunctions = false;
   this._color = 16711680;
   this._thick = 1;
   this._alpha = 80;
   this._back = this._parent._bC.createEmptyMovieClip("_" + depth,depth);
   this._front = this._parent._fC.createEmptyMovieClip("_" + depth,depth);
}
var p = CelestialSphereClass.prototype;
p.addCircle = function(name, style, definition, depth)
{
   if(depth == undefined)
   {
      depth = 0;
      while(this._fC["_" + depth] != undefined)
      {
         depth++;
      }
   }
   var id = this._circleFreeID++;
   this[name] = new CSCirclesClass(this,name,id,depth);
   this._circleList.push({id:id,name:this[name]});
   if(typeof style == "object")
   {
      this[name].setStyle(style.thickness,style.color,style.alpha);
   }
   if(typeof definition == "object")
   {
      this[name].setParameters(definition);
   }
   return this[name];
};
p.updateCircles = function(notHorizon)
{
   var start = getTimer();
   if(notHorizon)
   {
      var i = 0;
      while(i < this._circleList.length)
      {
         var circle = this._circleList[i].name;
         if(!circle._sys == 0)
         {
            circle.update();
         }
         i++;
      }
   }
   else
   {
      var i = 0;
      while(i < this._circleList.length)
      {
         this._circleList[i].name.update();
         i++;
      }
   }
   if(this._traceOn)
   {
      trace("circles: " + (getTimer() - start) + " ms");
   }
};
p.showCircles = function()
{
   var list = this._circleList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name.visible = true;
      i++;
   }
};
p.hideCircles = function()
{
   var list = this._circleList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name.visible = false;
      i++;
   }
};
p.removeCircles = function()
{
   var list = this._circleList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name._back.removeMovieClip();
      list[i].name._front.removeMovieClip();
      delete this[list[i].name._name];
      i++;
   }
   this._circleFreeID = 0;
   this._circleList = [];
};
var p = CSCirclesClass.prototype = new Object();
p._minStep = 0.7853981633974483;
p.toString = function()
{
   return String(this._parent) + "." + this._name + " (circle)";
};
p.remove = function()
{
   var list = this._parent._circleList;
   var i = 0;
   while(i < list.length)
   {
      if(list[i].id == this._id)
      {
         break;
      }
      i++;
   }
   list.splice(i,1);
   this._back.removeMovieClip();
   this._front.removeMovieClip();
   delete this._parent[this._name];
};
p.update = function()
{
   function drawArc(g1, g2, mc)
   {
      if(g2 < g1)
      {
         g2 += 6.283185307179586;
      }
      var arc = g2 - g1;
      if(arc == 0)
      {
         arc = 6.283185307179586;
      }
      var n = Math.ceil(arc / minStep);
      var step = arc / n;
      var halfStep = step / 2;
      var cos = Math.cos;
      var sin = Math.sin;
      var cRad = 1 / cos(halfStep);
      var ax = cos(g1);
      var ay = sin(g1);
      mc.moveTo(v0 * ax + v1 * ay + v2,v3 * ax + v4 * ay + v5);
      var aAngle = g1 + step;
      var cAngle = aAngle - halfStep;
      var i = 0;
      while(i < n)
      {
         var ax = cos(aAngle);
         var ay = sin(aAngle);
         var cx = cRad * cos(cAngle);
         var cy = cRad * sin(cAngle);
         mc.curveTo(v0 * cx + v1 * cy + v2,v3 * cx + v4 * cy + v5,v0 * ax + v1 * ay + v2,v3 * ax + v4 * ay + v5);
         aAngle += step;
         cAngle += step;
         i++;
      }
   }
   var frontMC = this._front;
   var backMC = this._back;
   frontMC.clear();
   backMC.clear();
   if(!this._visible)
   {
      return undefined;
   }
   frontMC.lineStyle(this._thick,this._color,this._alpha);
   backMC.lineStyle(this._thick,this._color,this._alpha);
   if(this._sys == 0 && (this._wLastVer != this._wVer || this._aLastVer != this._parent._aVer))
   {
      var tc = this._c;
      var pc = this._parent._c;
      var v0 = tc.v0 = pc.a0 * tc.w0 + pc.a1 * tc.w3;
      var v1 = tc.v1 = pc.a0 * tc.w1 + pc.a1 * tc.w4;
      var v2 = tc.v2 = pc.a0 * tc.w2 + pc.a1 * tc.w5;
      var v3 = tc.v3 = pc.a3 * tc.w0 + pc.a4 * tc.w3;
      var v4 = tc.v4 = pc.a3 * tc.w1 + pc.a4 * tc.w4 + pc.a5 * tc.w7;
      var v5 = tc.v5 = pc.a3 * tc.w2 + pc.a4 * tc.w5 + pc.a5 * tc.w8;
      var v6 = tc.v6 = pc.a6 * tc.w0 + pc.a7 * tc.w3;
      var v7 = tc.v7 = pc.a6 * tc.w1 + pc.a7 * tc.w4 + pc.a8 * tc.w7;
      var v8 = tc.v8 = pc.a6 * tc.w2 + pc.a7 * tc.w5 + pc.a8 * tc.w8;
      this._wLastVer = this._wVer;
      this._aLastVer = this._parent._aVer;
   }
   else if(this._sys == 1 && (this._wLastVer != this._wVer || this._bLastVer != this._parent._bVer))
   {
      var tc = this._c;
      var pc = this._parent._c;
      var v0 = tc.v0 = pc.b0 * tc.w0 + pc.b1 * tc.w3;
      var v1 = tc.v1 = pc.b0 * tc.w1 + pc.b1 * tc.w4 + pc.b2 * tc.w7;
      var v2 = tc.v2 = pc.b0 * tc.w2 + pc.b1 * tc.w5 + pc.b2 * tc.w8;
      var v3 = tc.v3 = pc.b3 * tc.w0 + pc.b4 * tc.w3;
      var v4 = tc.v4 = pc.b3 * tc.w1 + pc.b4 * tc.w4 + pc.b5 * tc.w7;
      var v5 = tc.v5 = pc.b3 * tc.w2 + pc.b4 * tc.w5 + pc.b5 * tc.w8;
      var v6 = tc.v6 = pc.b6 * tc.w0 + pc.b7 * tc.w3;
      var v7 = tc.v7 = pc.b6 * tc.w1 + pc.b7 * tc.w4 + pc.b8 * tc.w7;
      var v8 = tc.v8 = pc.b6 * tc.w2 + pc.b7 * tc.w5 + pc.b8 * tc.w8;
      this._wLastVer = this._wVer;
      this._bLastVer = this._parent._bVer;
   }
   else
   {
      var c = this._c;
      var v0 = c.v0;
      var v1 = c.v1;
      var v2 = c.v2;
      var v3 = c.v3;
      var v4 = c.v4;
      var v5 = c.v5;
      var v6 = c.v6;
      var v7 = c.v7;
      var v8 = c.v8;
   }
   var minStep = this._minStep;
   var A = Math.sqrt(v6 * v6 + v7 * v7);
   if(A == 0)
   {
      if(v8 < 0)
      {
         drawArc(this._gS,this._gE,backMC);
      }
      else
      {
         drawArc(this._gS,this._gE,frontMC);
      }
   }
   else
   {
      var sj = (- v8) / A;
      if(sj <= -1)
      {
         drawArc(this._gS,this._gE,frontMC);
      }
      else if(sj >= 1)
      {
         drawArc(this._gS,this._gE,backMC);
      }
      else
      {
         var j = Math.asin(sj);
         var t = Math.atan2(v6,v7);
         if(Math.cos(j) < 0)
         {
            var gDesc = ((j - t) % 6.283185307179586 + 6.283185307179586) % 6.283185307179586;
            var gAsc = ((3.141592653589793 - j - t) % 6.283185307179586 + 6.283185307179586) % 6.283185307179586;
         }
         else
         {
            var gDesc = ((3.141592653589793 - j - t) % 6.283185307179586 + 6.283185307179586) % 6.283185307179586;
            var gAsc = ((j - t) % 6.283185307179586 + 6.283185307179586) % 6.283185307179586;
         }
         if(this._gS == this._gE)
         {
            drawArc(gAsc,gDesc,frontMC);
            drawArc(gDesc,gAsc,backMC);
         }
         else
         {
            var gArray = [[gAsc,0],[gDesc,1],[this._gS,2],[this._gE,3]];
            gArray.sort(this.gSort);
            var draw = false;
            var front = true;
            var s = 0;
            while(s < 4)
            {
               if(gArray[s][1] == 0)
               {
                  front = true;
               }
               else if(gArray[s][1] == 1)
               {
                  front = false;
               }
               else if(gArray[s][1] == 2)
               {
                  draw = true;
               }
               else
               {
                  draw = false;
               }
               s++;
            }
            var g2 = gArray[3];
            var i = 0;
            while(i < 4)
            {
               g1 = g2;
               g2 = gArray[i];
               if(draw && g1[0] != g2[0])
               {
                  if(front)
                  {
                     drawArc(g1[0],g2[0],frontMC);
                  }
                  else
                  {
                     drawArc(g1[0],g2[0],backMC);
                  }
               }
               if(g2[1] == 0)
               {
                  front = true;
               }
               else if(g2[1] == 1)
               {
                  front = false;
               }
               else if(g2[1] == 2)
               {
                  draw = true;
               }
               else
               {
                  draw = false;
               }
               i++;
            }
         }
      }
   }
};
p.gSort = function(a, b)
{
   if(a[0] < b[0])
   {
      return -1;
   }
   if(a[0] > b[0])
   {
      return 1;
   }
   return 0;
};
p.setStyle = function(thickness, circleColor, alpha)
{
   if(thickness != undefined)
   {
      this._thick = thickness;
   }
   if(circleColor != undefined)
   {
      this._color = circleColor;
   }
   if(alpha != undefined)
   {
      this._alpha = alpha;
   }
};
p.setArcPoints = function(p1, p2)
{
   if(typeof p1 == "string")
   {
      var obj = this._parent[p1];
      if(!(obj instanceof CSObjectsClass))
      {
         return false;
      }
      this._sys = obj._sys;
      if(this._sys == 0)
      {
         var theta1 = (360 - obj.az) * 0.017453292519943295;
         var phi1 = obj.alt * 0.017453292519943295;
      }
      else
      {
         if(this._sys != 1)
         {
            return false;
         }
         var theta1 = obj.ra * 0.2617993877991494;
         var phi1 = obj.dec * 0.017453292519943295;
      }
   }
   else if(p1.az != undefined && p1.alt != undefined)
   {
      this._sys = 0;
      var theta1 = (360 - p1.az) * 0.017453292519943295;
      var phi1 = p1.alt * 0.017453292519943295;
   }
   else
   {
      if(!(p1.ra != undefined && p1.dec != undefined))
      {
         return false;
      }
      this._sys = 1;
      var theta1 = p1.ra * 0.2617993877991494;
      var phi1 = p1.dec * 0.017453292519943295;
   }
   if(typeof p2 == "string")
   {
      var obj = this._parent[p2];
      if(!(obj instanceof CSObjectsClass))
      {
         return false;
      }
      if(this._sys == 0)
      {
         var theta2 = (360 - obj.az) * 0.017453292519943295;
         var phi2 = obj.alt * 0.017453292519943295;
      }
      else
      {
         if(this._sys != 1)
         {
            return false;
         }
         var theta2 = obj.ra * 0.2617993877991494;
         var phi2 = obj.dec * 0.017453292519943295;
      }
   }
   else if(p2.az != undefined && p2.alt != undefined)
   {
      if(this._sys == 0)
      {
         var theta2 = (360 - p2.az) * 0.017453292519943295;
         var phi2 = p2.alt * 0.017453292519943295;
      }
      else if(this._sys == 1)
      {
         var cp = new Object();
         this._parent.MHtoC({az:(360 - p2.az) * 0.017453292519943295,alt:p2.alt * 0.017453292519943295},cp);
         var theta2 = cp.ra;
         var phi2 = cp.dec;
      }
   }
   else
   {
      if(!(p2.ra != undefined && p2.dec != undefined))
      {
         return false;
      }
      if(this._sys == 0)
      {
         var hp = new Object();
         this._parent.CtoMH({ra:p2.ra * 0.2617993877991494,dec:p2.dec * 0.017453292519943295},hp);
         var theta2 = hp.az;
         var phi2 = hp.alt;
      }
      else if(this._sys == 1)
      {
         var theta2 = p2.ra * 0.2617993877991494;
         var phi2 = p2.dec * 0.017453292519943295;
      }
   }
   var cp1 = Math.cos(phi1);
   var sp1 = z1 = Math.sin(phi1);
   var x1 = cp1 * Math.cos(theta1);
   var y1 = cp1 * Math.sin(theta1);
   var cp2 = Math.cos(phi2);
   var sp2 = z2 = Math.sin(phi2);
   var x2 = cp2 * Math.cos(theta2);
   var y2 = cp2 * Math.sin(theta2);
   var ax = y1 * z2 - y2 * z1;
   var ay = x2 * z1 - x1 * z2;
   var az = x1 * y2 - x2 * y1;
   var aN = Math.sqrt(ax * ax + ay * ay + az * az);
   if(aN < 0.000001)
   {
      if(x1 == x2 && y1 == y2 && z1 == z2)
      {
         return false;
      }
      this._lambda = 0;
      this._tilt = 1.5707963267948966;
      this._beta = Math.atan2(y1,x1);
      this._gS = Math.acos(Math.sqrt(x1 * x1 + y1 * y1));
      if(z1 < 0)
      {
         this._gS = - this._gS;
      }
      this._gS = this.mod(this._gS,6.283185307179586);
      this._gE = (this._gS + 3.141592653589793) % 6.283185307179586;
      this.doW();
      return true;
   }
   this._lambda = 0;
   this._tilt = Math.acos(az / aN);
   if(this._tilt == 0)
   {
      this._beta = 0;
      this._gS = this.mod(Math.atan2(y1,x1),6.283185307179586);
      this._gE = this.mod(Math.atan2(y2,x2),6.283185307179586);
   }
   else if(this._tilt == 3.141592653589793)
   {
      this._beta = 0;
      this._gS = this.mod(Math.atan2(- y1,x1),6.283185307179586);
      this._gE = this.mod(Math.atan2(- y2,x2),6.283185307179586);
   }
   else
   {
      this._beta = Math.atan2(ax,- ay);
      var st = Math.sin(this._tilt);
      this._gS = this.mod(Math.atan2(sp1 / st,cp1 * Math.cos(theta1 - this._beta)),6.283185307179586);
      this._gE = this.mod(Math.atan2(sp2 / st,cp2 * Math.cos(theta2 - this._beta)),6.283185307179586);
   }
   this.doW();
   return true;
};
p.setCircleParameters = p.setParameters = function(arg)
{
   if(arg.az != undefined && arg.alt != undefined && arg.tilt != undefined)
   {
      this._sys = 0;
      if(isFinite(arg.tilt))
      {
         if(arg.tilt < 0)
         {
            this._tilt = 0;
         }
         else if(arg.tilt > 180)
         {
            this._tilt = 3.141592653589793;
         }
         else
         {
            this._tilt = arg.tilt * 0.017453292519943295;
         }
      }
      if(isFinite(arg.alt))
      {
         if(arg.alt < -90)
         {
            this._lambda = -3.141592653589793;
         }
         else if(arg.alt > 90)
         {
            this._lambda = 3.141592653589793;
         }
         else
         {
            this._lambda = arg.alt * 0.017453292519943295;
         }
      }
      if(isFinite(arg.az))
      {
         this._beta = 0.017453292519943295 * this.mod(- arg.az,360);
      }
      if(isFinite(arg.gammaStart))
      {
         this._gS = 0.017453292519943295 * this.mod(arg.gammaStart,360);
      }
      if(isFinite(arg.gammaEnd))
      {
         this._gE = 0.017453292519943295 * this.mod(arg.gammaEnd,360);
      }
   }
   else if(arg.ra != undefined && arg.dec != undefined && arg.tilt != undefined)
   {
      this._sys = 1;
      if(isFinite(arg.tilt))
      {
         if(arg.tilt < 0)
         {
            this._tilt = 0;
         }
         else if(arg.tilt > 180)
         {
            this._tilt = 3.141592653589793;
         }
         else
         {
            this._tilt = arg.tilt * 0.017453292519943295;
         }
      }
      if(isFinite(arg.dec))
      {
         if(arg.dec < -90)
         {
            this._lambda = -3.141592653589793;
         }
         else if(arg.dec > 90)
         {
            this._lambda = 3.141592653589793;
         }
         else
         {
            this._lambda = arg.dec * 0.017453292519943295;
         }
      }
      if(isFinite(arg.ra))
      {
         this._beta = 0.2617993877991494 * this.mod(arg.ra,24);
      }
      if(isFinite(arg.gammaStart))
      {
         this._gS = 0.017453292519943295 * this.mod(arg.gammaStart,360);
      }
      if(isFinite(arg.gammaEnd))
      {
         this._gE = 0.017453292519943295 * this.mod(arg.gammaEnd,360);
      }
   }
   this.doW();
};
p.doW = function()
{
   var st = Math.sin(this._tilt);
   var ct = Math.cos(this._tilt);
   var sb = Math.sin(this._beta);
   var cb = Math.cos(this._beta);
   var cl = Math.cos(this._lambda);
   var sl = Math.sin(this._lambda);
   var c = this._c;
   c.w0 = cl * cb;
   c.w1 = (- cl) * sb * ct;
   c.w2 = sl * sb * st;
   c.w3 = cl * sb;
   c.w4 = cl * cb * ct;
   c.w5 = (- sl) * cb * st;
   c.w7 = cl * st;
   c.w8 = sl * ct;
   this._wVer++;
};
p.mod = function(n, m)
{
   return (n % m + m) % m;
};
p.getUseMouseFunctions = function()
{
   return this._useMouseFunctions;
};
p.setUseMouseFunctions = function(arg, options)
{
   this._useMouseFunctions = Boolean(arg);
   var enableFront = enableBack = this._useMouseFunctions;
   if(options == "back only")
   {
      enableFront = false;
   }
   else if(options == "front only")
   {
      enableBack = false;
   }
   if(enableFront)
   {
      this._front.useHandCursor = false;
      this._front._thisCircle = this;
      this._front._callInst = this._parent._parent;
      this._front.onRollOver = function()
      {
         this._thisCircle.onRollOver.call(this._callInst,"front");
      };
      this._front.onRollOut = function()
      {
         this._thisCircle.onRollOut.call(this._callInst,"front");
      };
      this._front.onRelease = function()
      {
         this._thisCircle.onRelease.call(this._callInst,"front");
      };
      this._front.onReleaseOutside = function()
      {
         this._thisCircle.onReleaseOutside.call(this._callInst,"front");
      };
      this._front.onPress = function()
      {
         this._thisCircle.onPress.call(this._callInst,"front");
      };
   }
   else
   {
      delete this._front.onRollOver;
      delete this._front.onRollOut;
      delete this._front.onRelease;
      delete this._front.onReleaseOutside;
      delete this._front.onPress;
   }
   if(enableBack)
   {
      this._back.useHandCursor = false;
      this._back._thisCircle = this;
      this._back._callInst = this._parent._parent;
      this._back.onRollOver = function()
      {
         this._thisCircle.onRollOver.call(this._callInst,"back");
      };
      this._back.onRollOut = function()
      {
         this._thisCircle.onRollOut.call(this._callInst,"back");
      };
      this._back.onRelease = function()
      {
         this._thisCircle.onRelease.call(this._callInst,"back");
      };
      this._back.onReleaseOutside = function()
      {
         this._thisCircle.onReleaseOutside.call(this._callInst,"back");
      };
      this._back.onPress = function()
      {
         this._thisCircle.onPress.call(this._callInst,"back");
      };
   }
   else
   {
      delete this._back.onRollOver;
      delete this._back.onRollOut;
      delete this._back.onRelease;
      delete this._back.onReleaseOutside;
      delete this._back.onPress;
   }
};
p.getGammaStart = function()
{
   return 57.29577951308232 * this._gS;
};
p.setGammaStart = function(arg)
{
   if(isFinite(arg))
   {
      this._gS = 0.017453292519943295 * this.mod(arg,360);
   }
};
p.getGammaEnd = function()
{
   return 57.29577951308232 * this._gE;
};
p.setGammaEnd = function(arg)
{
   if(isFinite(arg))
   {
      this._gE = 0.017453292519943295 * this.mod(arg,360);
   }
};
p.getTilt = function()
{
   return this._tilt * 57.29577951308232;
};
p.setTilt = function(arg)
{
   if(isFinite(arg))
   {
      if(arg < 0)
      {
         this._tilt = 0;
      }
      else if(arg > 180)
      {
         this._tilt = 3.141592653589793;
      }
      else
      {
         this._tilt = arg * 0.017453292519943295;
      }
      this.doW();
   }
};
p.getLambda = function()
{
   return this._lambda * 57.29577951308232;
};
p.setLambda = function(arg)
{
   if(isFinite(arg))
   {
      if(arg < -90)
      {
         this._lambda = -3.141592653589793;
      }
      else if(arg > 90)
      {
         this._lambda = 3.141592653589793;
      }
      else
      {
         this._lambda = arg * 0.017453292519943295;
      }
      this.doW();
      return true;
   }
};
p.setAlt = function(arg)
{
   if(this.setLambda(arg))
   {
      this._sys = 0;
   }
};
p.setDec = function(arg)
{
   if(this.setLambda(arg))
   {
      this._sys = 1;
   }
};
p.getBeta = function()
{
   return this._beta * 57.29577951308232;
};
p.setBeta = function(arg)
{
   if(isFinite(arg))
   {
      this._beta = 0.017453292519943295 * this.mod(arg,360);
      this.doW();
      return true;
   }
};
p.getAz = function()
{
   return this.mod(- this.getBeta(),360);
};
p.setAz = function(arg)
{
   if(this.setBeta(- arg))
   {
      this._sys = 0;
   }
};
p.getRa = function()
{
   return this.getBeta() / 15;
};
p.setRa = function(arg)
{
   if(this.setBeta(15 * arg))
   {
      this._sys = 1;
   }
};
p.getVisible = function()
{
   return this._visible;
};
p.setVisible = function(arg)
{
   this._visible = Boolean(arg);
   this.update();
};
p.addProperty("useMouseFunctions",p.getUseMouseFunctions,p.setUseMouseFunctions);
p.addProperty("gammaStart",p.getGammaStart,p.setGammaStart);
p.addProperty("gammaEnd",p.getGammaEnd,p.setGammaEnd);
p.addProperty("tilt",p.getTilt,p.setTilt);
p.addProperty("alt",p.getLambda,p.setAlt);
p.addProperty("dec",p.getLambda,p.setDec);
p.addProperty("az",p.getAz,p.setAz);
p.addProperty("ra",p.getRa,p.setRa);
p.addProperty("visible",p.getVisible,p.setVisible);
