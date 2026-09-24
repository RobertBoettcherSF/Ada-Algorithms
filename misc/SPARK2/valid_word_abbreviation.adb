pragma Ada_2022;

package body Valid_Word_Abbreviation with SPARK_Mode => On is
   function Is_Valid
     (Word : Text_Array; Abbreviation : Abbreviation_Array) return Boolean is
   begin
      return Abbreviation (1) = Word (1)
        and then Abbreviation (2) = Word (2)
        and then Abbreviation (3) = '2'
        and then Abbreviation (4) = Word (5)
        and then Abbreviation (5) = Word (6);
   end Is_Valid;
end Valid_Word_Abbreviation;
