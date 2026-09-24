pragma Ada_2022;
package body Partition_Equal_Subset_Sum with SPARK_Mode => On is
   function Can_Partition (A : Values) return Boolean is
      Total : constant Natural := A (1) + A (2) + A (3) + A (4) + A (5) + A (6);
      Half : constant Natural := Total / 2;
   begin
      if Total mod 2 /= 0 then
         return False;
      end if;
      -- Enumerate subsets omitting the last element; complements cover the rest.
      return
        0 = Half
        or A (1) = Half
        or A (2) = Half
        or A (1) + A (2) = Half
        or A (3) = Half
        or A (1) + A (3) = Half
        or A (2) + A (3) = Half
        or A (1) + A (2) + A (3) = Half
        or A (4) = Half
        or A (1) + A (4) = Half
        or A (2) + A (4) = Half
        or A (1) + A (2) + A (4) = Half
        or A (3) + A (4) = Half
        or A (1) + A (3) + A (4) = Half
        or A (2) + A (3) + A (4) = Half
        or A (1) + A (2) + A (3) + A (4) = Half
        or A (5) = Half
        or A (1) + A (5) = Half
        or A (2) + A (5) = Half
        or A (1) + A (2) + A (5) = Half
        or A (3) + A (5) = Half
        or A (1) + A (3) + A (5) = Half
        or A (2) + A (3) + A (5) = Half
        or A (1) + A (2) + A (3) + A (5) = Half
        or A (4) + A (5) = Half
        or A (1) + A (4) + A (5) = Half
        or A (2) + A (4) + A (5) = Half
        or A (1) + A (2) + A (4) + A (5) = Half
        or A (3) + A (4) + A (5) = Half
        or A (1) + A (3) + A (4) + A (5) = Half
        or A (2) + A (3) + A (4) + A (5) = Half
        or A (1) + A (2) + A (3) + A (4) + A (5) = Half;
   end Can_Partition;
end Partition_Equal_Subset_Sum;
