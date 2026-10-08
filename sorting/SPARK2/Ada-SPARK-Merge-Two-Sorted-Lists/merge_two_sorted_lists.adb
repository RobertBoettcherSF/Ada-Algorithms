pragma Ada_2022;
pragma SPARK_Mode (On);
package body Merge_Two_Sorted_Lists is
   function Empty return List is begin return (Data => [others => 0], Size => 0); end Empty;
   procedure Append (L : in out List; V : Value) is
   begin L.Size := L.Size + 1; L.Data (L.Size) := V; end Append;
   function Element (L : List; P : Position) return Value is begin return L.Data (P); end Element;
   function Merge (A, B : List) return List is
      R : List := Empty;
      I : Positive := 1;   --  next unread position of A
      J : Positive := 1;   --  next unread position of B
   begin
      while I <= A.Size or else J <= B.Size loop
         pragma Loop_Invariant (I <= A.Size + 1 and then J <= B.Size + 1
                                and then Length (R) = (I - 1) + (J - 1));
         pragma Loop_Variant (Increases => I + J);
         if J > B.Size or else (I <= A.Size and then A.Data (I) <= B.Data (J)) then
            Append (R, A.Data (I));
            I := I + 1;
         else
            Append (R, B.Data (J));
            J := J + 1;
         end if;
      end loop;
      return R;
   end Merge;
end Merge_Two_Sorted_Lists;
