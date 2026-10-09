pragma Ada_2022;

package body Majority_Element with SPARK_Mode => On is
   --  Boyer-Moore voting: Balance counts the current Candidate's surplus
   --  over the elements seen so far; at zero the next element takes over.
   function Find (Input : Input_Array) return Value is
      Candidate : Value := Input (Index'First);
      Balance   : Natural := 1;
   begin
      for I in Index'First + 1 .. Index'Last loop
         pragma Loop_Invariant (Balance <= I - Index'First);
         if Balance = 0 then
            Candidate := Input (I);
            Balance := 1;
         elsif Input (I) = Candidate then
            Balance := Balance + 1;
         else
            Balance := Balance - 1;
         end if;
      end loop;
      return Candidate;
   end Find;
end Majority_Element;
