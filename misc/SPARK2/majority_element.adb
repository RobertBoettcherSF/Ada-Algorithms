pragma Ada_2022;

package body Majority_Element with SPARK_Mode => On is
   function Find (Input : Input_Array) return Value is
      Candidate : Value := Input (1);
      Balance : Integer := 1;
   begin
      if Input (2) = Candidate then Balance := Balance + 1;
      else Balance := Balance - 1; end if;
      if Balance = 0 then Candidate := Input (3); Balance := 1;
      elsif Input (3) = Candidate then Balance := Balance + 1;
      else Balance := Balance - 1; end if;
      if Balance = 0 then Candidate := Input (4); Balance := 1;
      elsif Input (4) = Candidate then Balance := Balance + 1;
      else Balance := Balance - 1; end if;
      if Balance = 0 then Candidate := Input (5); Balance := 1;
      elsif Input (5) = Candidate then Balance := Balance + 1;
      else Balance := Balance - 1; end if;
      if Balance = 0 then Candidate := Input (6); Balance := 1;
      elsif Input (6) = Candidate then Balance := Balance + 1;
      else Balance := Balance - 1; end if;
      if Balance = 0 then Candidate := Input (7); end if;
      return Candidate;
   end Find;
end Majority_Element;
