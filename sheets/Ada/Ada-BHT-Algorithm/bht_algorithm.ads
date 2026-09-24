package BHT_Algorithm is

   type Domain_Value is new Positive;
   type Range_Value is new Natural;

   type Collision_Pair is record
      X1 : Domain_Value;
      X2 : Domain_Value;
   end record;

   type Oracle_Function is access function (X : Domain_Value) return Range_Value;

   Invalid_Domain_Error : exception;
   Invalid_R_Error      : exception;
   Null_Oracle_Error    : exception;

   -- Standard BHT algorithm for 2-to-1 functions
   procedure Simulate_BHT_2_To_1
     (Domain_Size : Domain_Value;
      Oracle      : Oracle_Function;
      Result      : out Collision_Pair;
      Found       : out Boolean)
     with 
       Pre  => Domain_Size >= 2,
       Post => (if Found then Result.X1 /= Result.X2 and Oracle (Result.X1) = Oracle (Result.X2));

   -- Generalized BHT algorithm for R-to-1 functions
   procedure Simulate_BHT_R_To_1
     (Domain_Size : Domain_Value;
      R           : Positive;
      Oracle      : Oracle_Function;
      Result      : out Collision_Pair;
      Found       : out Boolean)
     with 
       Pre  => Domain_Size >= Domain_Value (R) and R >= 2,
       Post => (if Found then Result.X1 /= Result.X2 and Oracle (Result.X1) = Oracle (Result.X2));

end BHT_Algorithm;
