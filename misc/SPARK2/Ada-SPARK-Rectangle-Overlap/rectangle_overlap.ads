pragma Ada_2022;
package Rectangle_Overlap with SPARK_Mode => On is
   subtype Coordinate is Integer range 0 .. 10;
   type Rectangle is record
      Left, Bottom, Right, Top : Coordinate;
   end record;
   function Has_Overlap (A, B : Rectangle) return Boolean
     with Global => null,
          Pre => A.Left <= A.Right and A.Bottom <= A.Top
             and B.Left <= B.Right and B.Bottom <= B.Top;
end Rectangle_Overlap;
