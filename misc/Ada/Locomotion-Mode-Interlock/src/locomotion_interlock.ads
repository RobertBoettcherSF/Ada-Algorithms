-- Clean-room educational locomotion interlock (not Rivr proprietary).
pragma SPARK_Mode (On);

package Locomotion_Interlock
  with SPARK_Mode => On
is
   type Mode is (Wheels, Legs, Hybrid_Transition, Safe_Stop);

   type Status is (Ok, Rejected);

   subtype Speed_Cm_S is Natural range 0 .. 500;

   type Interlock is private;

   Max_Wheels : constant Speed_Cm_S := 200;
   Max_Legs   : constant Speed_Cm_S := 80;
   Max_Hybrid : constant Speed_Cm_S := 40;
   Max_Stop   : constant Speed_Cm_S := 0;

   procedure Init (I : out Interlock)
     with Global => null,
          Post   => Current_Mode (I) = Safe_Stop;

   function Current_Mode (I : Interlock) return Mode
     with Global => null;

   function Wheels_Armed (I : Interlock) return Boolean
     with Global => null;

   function Speed_Limit (M : Mode) return Speed_Cm_S
     with Global => null;

   procedure Set_Wheels_Armed (I : in out Interlock; Armed : Boolean)
     with Global => null;

   procedure Request_Mode
     (I      : in out Interlock;
      Next   : Mode;
      Result : out Status)
     with Global => null;

   procedure Request_Stairs
     (I      : in out Interlock;
      Result : out Status)
     with Global => null;
   -- Stairs require Legs or Hybrid_Transition; Wheels-only rejected.

private
   type Interlock is record
      Cur          : Mode := Safe_Stop;
      Wheels_Arm   : Boolean := False;
      Stairs_Req   : Boolean := False;
   end record;

   function Current_Mode (I : Interlock) return Mode is (I.Cur);
   function Wheels_Armed (I : Interlock) return Boolean is (I.Wheels_Arm);

   function Speed_Limit (M : Mode) return Speed_Cm_S is
     (case M is
         when Wheels            => Max_Wheels,
         when Legs              => Max_Legs,
         when Hybrid_Transition => Max_Hybrid,
         when Safe_Stop         => Max_Stop);

end Locomotion_Interlock;
