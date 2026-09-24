--  Traffic_Phases
--  Clean-room educational package: signal and pedestrian phase enums.
--  Not derived from AdaCore gnat-foundry-intersection sources.

package Traffic_Phases is
   pragma Pure;

   type Signal_Color is (Red, Yellow, Green);

   --  Optional pedestrian indications (paired with vehicle axis).
   type Pedestrian_Indication is (Dont_Walk, Walk);

   function Is_Stop (C : Signal_Color) return Boolean
     with Inline;
   --  Red or Yellow: vehicles must not proceed as if green.

   function Is_Proceed (C : Signal_Color) return Boolean
     with Inline;
   --  Green only.

   function Conflicts (A, B : Signal_Color) return Boolean
     with Inline;
   --  True when both axes would allow conflicting vehicle movement
   --  (both Green). Yellow+Green is also treated as unsafe overlap.

   function Pedestrian_For (C : Signal_Color) return Pedestrian_Indication
     with Inline;
   --  Walk only while the parallel vehicle signal is Green.

end Traffic_Phases;
