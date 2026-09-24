-- Clean-room educational model: corporate subsidiary profile.
-- Inspired by public Wikipedia description of CyberStorm 2: Corporate Wars.
-- No Dynamix/Sierra code, assets, or proprietary unit names.

package Corp_Profile is

   pragma Pure;

   subtype Deploy_Count is Positive range 4 .. 8;

   -- Multipliers scale base finance / research / military throughput.
   type Multiplier is digits 6 range 0.25 .. 4.0;

   type Profile is record
      Finance_Mult  : Multiplier := 1.0;
      Research_Mult : Multiplier := 1.0;
      Military_Mult : Multiplier := 1.0;
      Max_Deploy    : Deploy_Count := 4;
   end record;

   function Balanced return Profile;
   function Finance_Heavy return Profile;
   function Research_Heavy return Profile;
   function Military_Heavy return Profile;

   function Can_Deploy (P : Profile; Units : Natural) return Boolean;

end Corp_Profile;
