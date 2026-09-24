pragma Ada_2022;

package Car_Pooling with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Passengers is Integer range 0 .. 4;
   subtype Capacity is Integer range 0 .. Size * Passengers'Last;
   type Trip is record
      People : Passengers;
      Pickup : Index;
      Dropoff : Index;
   end record;
   type Trips is array (Index) of Trip;

   function Feasible (T : Trips; Limit : Capacity) return Boolean
     with Global => null;
end Car_Pooling;
