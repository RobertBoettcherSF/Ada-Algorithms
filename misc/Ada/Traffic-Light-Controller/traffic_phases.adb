package body Traffic_Phases is

   function Is_Stop (C : Signal_Color) return Boolean is
   begin
      return C = Red or else C = Yellow;
   end Is_Stop;

   function Is_Proceed (C : Signal_Color) return Boolean is
   begin
      return C = Green;
   end Is_Proceed;

   function Conflicts (A, B : Signal_Color) return Boolean is
   begin
      --  Never allow simultaneous Green; also reject Green overlapping Yellow
      --  on the cross axis (clearance incomplete).
      return (A = Green and then B = Green)
        or else (A = Green and then B = Yellow)
        or else (A = Yellow and then B = Green);
   end Conflicts;

   function Pedestrian_For (C : Signal_Color) return Pedestrian_Indication is
   begin
      if C = Green then
         return Walk;
      else
         return Dont_Walk;
      end if;
   end Pedestrian_For;

end Traffic_Phases;
