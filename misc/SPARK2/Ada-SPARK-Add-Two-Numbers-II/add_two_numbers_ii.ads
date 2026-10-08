pragma SPARK_Mode (On);

package Add_Two_Numbers_II is
   subtype Number is Natural range 0 .. 10_000;
   subtype Sum is Natural range 0 .. 20_000;

   procedure Add (Left, Right : Number; Result : out Sum)
     with Global => null;
end Add_Two_Numbers_II;
