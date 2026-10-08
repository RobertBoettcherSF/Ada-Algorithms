pragma Ada_2022;
package body Chebyshev_Distance with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
      D1 : constant Integer := abs (Integer (A (1)) - Integer (B (1)));
      D2 : constant Integer := abs (Integer (A (2)) - Integer (B (2)));
      D3 : constant Integer := abs (Integer (A (3)) - Integer (B (3)));
   begin
      return (if D1 >= D2 and then D1 >= D3 then D1
              elsif D2 >= D3 then D2
              else D3);
   end Distance;
end Chebyshev_Distance;
