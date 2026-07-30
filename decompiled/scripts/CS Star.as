function CSStarClass()
{
   this.stop();
}
var p = CSStarClass.prototype = new MovieClip();
Object.registerClass("CS Star",CSStarClass);
p.setShowOutline = function(arg)
{
   if(arg)
   {
      this.gotoAndStop(2);
   }
   else
   {
      this.gotoAndStop(1);
   }
};
