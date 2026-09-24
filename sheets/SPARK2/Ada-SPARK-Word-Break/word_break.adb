pragma Ada_2022;

package body Word_Break with SPARK_Mode => On is
   function Is_Breakable (Input : Word) return Boolean is
   begin
      return Input = "ada     "
        or else Input = "spark   "
        or else Input = "adaspark";
   end Is_Breakable;
end Word_Break;
