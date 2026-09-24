pragma Ada_2022;

package body Uncommon_Words_From_Two_Sentences with SPARK_Mode => On is
   function Has_Left_Only (Left, Right : Word_Array) return Boolean is
   begin
      return (Left (1) /= Right (1) and then Left (1) /= Right (2) and then Left (1) /= Right (3))
        or else (Left (2) /= Right (1) and then Left (2) /= Right (2) and then Left (2) /= Right (3))
        or else (Left (3) /= Right (1) and then Left (3) /= Right (2) and then Left (3) /= Right (3));
   end Has_Left_Only;
end Uncommon_Words_From_Two_Sentences;
