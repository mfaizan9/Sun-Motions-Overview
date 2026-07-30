function CSLinesClass(parent, name, id, style, head, tail, depth)
{
   this._parent = parent;
   this._name = name;
   this._id = id;
   this.setStyle(1,255,100);
   if(typeof style == "object")
   {
      this.setStyle(style.thickness,style.color,style.alpha);
   }
   this._visible = true;
   this._head = new Object();
   this._tail = new Object();
   this.setPoints(head,tail);
   this._bE = this._parent._bEL.createEmptyMovieClip("_" + depth,depth);
   this._fE = this._parent._fEL.createEmptyMovieClip("_" + depth,depth);
   this._aI = this._parent._iLA.createEmptyMovieClip("_" + depth,depth);
   this._bI = this._parent._iLB.createEmptyMovieClip("_" + depth,depth);
}
var p = CelestialSphereClass.prototype;
p.addLine = function(name, style, head, tail, depth)
{
   if(depth == undefined)
   {
      depth = 0;
      while(this._fEL["_" + depth] != undefined)
      {
         depth++;
      }
   }
   var id = this._lineFreeID++;
   this[name] = new CSLinesClass(this,name,id,style,head,tail,depth);
   this._lineList.push({id:id,name:this[name]});
   return this[name];
};
p.updateLines = function(notHorizon)
{
   var start = getTimer();
   if(notHorizon)
   {
      var i = 0;
      while(i < this._lineList.length)
      {
         var line = this._lineList[i].name;
         if(line._head.sys != 0 || line._tail.sys != 0)
         {
            line.update();
         }
         i++;
      }
   }
   else
   {
      var i = 0;
      while(i < this._lineList.length)
      {
         this._lineList[i].name.update();
         i++;
      }
   }
   if(this._traceOn)
   {
      trace("lines: " + (getTimer() - start) + " ms");
   }
};
p.showLines = function()
{
   var list = this._lineList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name.visible = true;
      i++;
   }
};
p.hideLines = function()
{
   var list = this._lineList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name.visible = false;
      i++;
   }
};
p.removeLines = function()
{
   var list = this._lineList;
   var i = 0;
   while(i < list.length)
   {
      list[i].name._bE.removeMovieClip();
      list[i].name._fE.removeMovieClip();
      list[i].name._aI.removeMovieClip();
      list[i].name._bI.removeMovieClip();
      delete this[list[i].name._name];
      i++;
   }
   this._lineFreeID = 0;
   this._lineList = [];
};
var p = CSLinesClass.prototype = new Object();
p.toString = function()
{
   return String(this._parent) + "." + this._name + " (line)";
};
p.update = function()
{
   var bE = this._bE;
   var fE = this._fE;
   var aI = this._aI;
   var bI = this._bI;
   bE.clear();
   fE.clear();
   aI.clear();
   bI.clear();
   if(!this._visible)
   {
      return undefined;
   }
   var head = {};
   var tail = {};
   if(this._head.sys == 0)
   {
      this._parent.WtoSz(this._head,head);
   }
   else
   {
      if(this._head.sys != 1)
      {
         return undefined;
      }
      this._parent.CtoSz(this._head,head);
   }
   if(this._tail.sys == 0)
   {
      this._parent.WtoSz(this._tail,tail);
   }
   else
   {
      if(this._tail.sys != 1)
      {
         return undefined;
      }
      this._parent.CtoSz(this._tail,tail);
   }
   var mx = head.x - tail.x;
   var my = head.y - tail.y;
   var mz = head.z - tail.z;
   var A = mx * mx + my * my + mz * mz;
   var B = 2 * (mx * tail.x + my * tail.y + mz * tail.z);
   var C = tail.x * tail.x + tail.y * tail.y + tail.z * tail.z;
   var rad = this._parent._c.r;
   var rad2 = rad * rad;
   var phi = this._parent._phi;
   var stmp = [];
   var D = B * B - 4 * A * (C - rad2);
   if(D > 0)
   {
      var sD = Math.sqrt(D);
      stmp.push((- B + sD) / (2 * A));
      stmp.push((- B - sD) / (2 * A));
   }
   if(phi > -1.5707963267948966 && phi < 1.5707963267948966)
   {
      var tp = Math.tan(phi);
      if(my != tp * mz)
      {
         stmp.push((tp * tail.z - tail.y) / (my - tp * mz));
      }
      if(mz != 0)
      {
         var tmp = (- tail.z) / mz;
         if(tmp * (tmp * A + B) + C >= rad2)
         {
            stmp.push(tmp);
         }
      }
   }
   else if(mz != 0)
   {
      stmp.push((- tail.z) / mz);
   }
   var s = [0,1];
   var i = 0;
   while(i < stmp.length)
   {
      if(stmp[i] > 0 && stmp[i] < 1)
      {
         var k = 1;
         while(stmp[i] > s[k])
         {
            k++;
         }
         if(stmp[i] != s[k])
         {
            s.splice(k,0,stmp[i]);
         }
      }
      i++;
   }
   if(this._parent._showUnder)
   {
      var i = 0;
      while(i < s.length - 1)
      {
         var s1 = s[i];
         var s2 = s[i + 1];
         var mc;
         var u = s1 + (s2 - s1) / 2;
         var r2 = u * (u * A + B) + C;
         if(r2 < rad2)
         {
            if(phi == -1.5707963267948966)
            {
               if(u * mz + tail.z > 0)
               {
                  mc = bI;
               }
               else
               {
                  mc = aI;
               }
            }
            else if(phi == 1.5707963267948966)
            {
               if(u * mz + tail.z > 0)
               {
                  mc = aI;
               }
               else
               {
                  mc = bI;
               }
            }
            else if(u * my + tail.y - (u * mz + tail.z) * tp > 1e-9)
            {
               mc = bI;
            }
            else
            {
               mc = aI;
            }
         }
         else if(u * mz + tail.z < 0)
         {
            mc = bE;
         }
         else
         {
            mc = fE;
         }
         mc.lineStyle(this._thick,this._color,this._alpha);
         mc.moveTo(s1 * mx + tail.x,s1 * my + tail.y);
         mc.lineTo(s2 * mx + tail.x,s2 * my + tail.y);
         i++;
      }
   }
   else
   {
      var i = 0;
      for(; i < s.length - 1; i++)
      {
         var s1 = s[i];
         var s2 = s[i + 1];
         var mc;
         var u = s1 + (s2 - s1) / 2;
         var r2 = u * (u * A + B) + C;
         if(r2 < rad2)
         {
            if(phi == -1.5707963267948966)
            {
               if(u * mz + tail.z > 0)
               {
                  continue;
               }
               mc = aI;
            }
            else if(phi == 1.5707963267948966)
            {
               if(u * mz + tail.z <= 0)
               {
                  continue;
               }
               mc = aI;
            }
            else
            {
               if(u * my + tail.y - (u * mz + tail.z) * tp > 1e-9)
               {
                  continue;
               }
               mc = aI;
            }
         }
         else if(phi == -1.5707963267948966)
         {
            if(u * mz + tail.z > 0)
            {
               continue;
            }
            mc = bE;
         }
         else if(phi == 1.5707963267948966)
         {
            if(u * mz + tail.z <= 0)
            {
               continue;
            }
            mc = fE;
         }
         else
         {
            if(u * my + tail.y - (u * mz + tail.z) * tp > 1e-9)
            {
               continue;
            }
            if(u * mz + tail.z < 0)
            {
               mc = bE;
            }
            else
            {
               mc = fE;
            }
         }
         mc.lineStyle(this._thick,this._color,this._alpha);
         mc.moveTo(s1 * mx + tail.x,s1 * my + tail.y);
         mc.lineTo(s2 * mx + tail.x,s2 * my + tail.y);
      }
   }
};
p.remove = function()
{
   var list = this._parent._lineList;
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
   this._bE.removeMovieClip();
   this._fE.removeMovieClip();
   this._aI.removeMovieClip();
   this._bI.removeMovieClip();
   delete this._parent[this._name];
};
p.setStyle = function(thickness, lineColor, alpha)
{
   if(thickness != undefined)
   {
      this._thick = thickness;
   }
   if(lineColor != undefined)
   {
      this._color = lineColor;
   }
   if(alpha != undefined)
   {
      this._alpha = alpha;
   }
};
p.setPoints = function(head, tail)
{
   this.setHeadPoint(head);
   this.setTailPoint(tail);
};
p.setTailPoint = function(tail)
{
   this._parent.parsePointInput(tail,this._tail);
   if(this._tail.sys == -1)
   {
      this._tail.sys = 0;
   }
};
p.setHeadPoint = function(head)
{
   this._parent.parsePointInput(head,this._head);
   if(this._head.sys == -1)
   {
      this._head.sys = 0;
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
p.addProperty("visible",p.getVisible,p.setVisible);
