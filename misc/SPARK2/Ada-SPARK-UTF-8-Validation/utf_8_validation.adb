pragma Ada_2022;
package body UTF_8_Validation with SPARK_Mode => On is
   function Is_Valid (A : Byte_Array) return Boolean is
      I : Integer := A'First;
      L : Seq_Length;
   begin
      while I <= A'Last loop
         pragma Loop_Invariant (I in A'First .. A'Last);
         --  I is a sequence boundary: no sequence started before I reaches it
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 => J + Seq_Len (A (J)) <= I);
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 =>
              (if Is_Cont (A (J)) then Covered (A, J) else Lead_Ok (A, J)));
         pragma Loop_Variant (Increases => I);
         L := Seq_Len (A (I));
         if L = 0 then
            pragma Assert (if Is_Cont (A (I)) then not Covered (A, I));
            return False;
         elsif L - 1 > A'Last - I then
            return False;
         elsif L >= 2 and then not Second_Ok (A (I), A (I + 1)) then
            return False;
         elsif L >= 3 and then not Is_Cont (A (I + 2)) then
            return False;
         elsif L = 4 and then not Is_Cont (A (I + 3)) then
            return False;
         end if;
         pragma Assert (Lead_Ok (A, I));
         pragma Assert (for all K in 1 .. L - 1 => Is_Cont (A (I + K)));
         pragma Assert (for all K in 1 .. L - 1 => Seq_Len (A (I + K)) = 0);
         pragma Assert (for all K in 1 .. L - 1 => Covered (A, I + K));
         exit when L - 1 = A'Last - I;
         I := I + L;
      end loop;
      return True;
   end Is_Valid;
end UTF_8_Validation;
