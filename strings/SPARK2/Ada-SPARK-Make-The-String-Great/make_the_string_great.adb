pragma Ada_2022;

package body Make_The_String_Great with SPARK_Mode => On is
   function Opposite (Left, Right : Character) return Boolean is
   begin
      return (Left = 'a' and then Right = 'A') or else (Left = 'A' and then Right = 'a')
        or else (Left = 'b' and then Right = 'B') or else (Left = 'B' and then Right = 'b')
        or else (Left = 'c' and then Right = 'C') or else (Left = 'C' and then Right = 'c')
        or else (Left = 'd' and then Right = 'D') or else (Left = 'D' and then Right = 'd')
        or else (Left = 'e' and then Right = 'E') or else (Left = 'E' and then Right = 'e')
        or else (Left = 'f' and then Right = 'F') or else (Left = 'F' and then Right = 'f')
        or else (Left = 'g' and then Right = 'G') or else (Left = 'G' and then Right = 'g')
        or else (Left = 'h' and then Right = 'H') or else (Left = 'H' and then Right = 'h')
        or else (Left = 'i' and then Right = 'I') or else (Left = 'I' and then Right = 'i')
        or else (Left = 'j' and then Right = 'J') or else (Left = 'J' and then Right = 'j')
        or else (Left = 'k' and then Right = 'K') or else (Left = 'K' and then Right = 'k')
        or else (Left = 'l' and then Right = 'L') or else (Left = 'L' and then Right = 'l')
        or else (Left = 'm' and then Right = 'M') or else (Left = 'M' and then Right = 'm')
        or else (Left = 'n' and then Right = 'N') or else (Left = 'N' and then Right = 'n')
        or else (Left = 'o' and then Right = 'O') or else (Left = 'O' and then Right = 'o')
        or else (Left = 'p' and then Right = 'P') or else (Left = 'P' and then Right = 'p')
        or else (Left = 'q' and then Right = 'Q') or else (Left = 'Q' and then Right = 'q')
        or else (Left = 'r' and then Right = 'R') or else (Left = 'R' and then Right = 'r')
        or else (Left = 's' and then Right = 'S') or else (Left = 'S' and then Right = 's')
        or else (Left = 't' and then Right = 'T') or else (Left = 'T' and then Right = 't')
        or else (Left = 'u' and then Right = 'U') or else (Left = 'U' and then Right = 'u')
        or else (Left = 'v' and then Right = 'V') or else (Left = 'V' and then Right = 'v')
        or else (Left = 'w' and then Right = 'W') or else (Left = 'W' and then Right = 'w')
        or else (Left = 'x' and then Right = 'X') or else (Left = 'X' and then Right = 'x')
        or else (Left = 'y' and then Right = 'Y') or else (Left = 'Y' and then Right = 'y')
        or else (Left = 'z' and then Right = 'Z') or else (Left = 'Z' and then Right = 'z');
   end Opposite;

   procedure Make_Great (Input : Text; Length : Length_Type;
                         Output : out Text; Output_Length : out Length_Type) is
      Write : Length_Type := 0;
   begin
      Output := Input;
      for I in 1 .. Length loop
         if Write > 0 and then Opposite (Output (Index (Write)), Input (Index (I))) then
            Write := Write - 1;
         elsif Write < 32 then
            Write := Write + 1;
            Output (Index (Write)) := Input (Index (I));
         end if;
      end loop;
      Output_Length := Write;
   end Make_Great;
end Make_The_String_Great;
