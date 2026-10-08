pragma Ada_2022;
package body Bitwise_XOR_Of_All_Pairings with SPARK_Mode => On is
   use type Word;
   function Pairings_Xor (Left, Right : Triple) return Word is
   begin
      return (Left (1) xor Right (1)) xor (Left (1) xor Right (2)) xor
        (Left (1) xor Right (3)) xor (Left (2) xor Right (1)) xor
        (Left (2) xor Right (2)) xor (Left (2) xor Right (3)) xor
        (Left (3) xor Right (1)) xor (Left (3) xor Right (2)) xor
        (Left (3) xor Right (3));
   end Pairings_Xor;
end Bitwise_XOR_Of_All_Pairings;
