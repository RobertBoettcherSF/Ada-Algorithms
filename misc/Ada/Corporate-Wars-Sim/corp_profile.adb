package body Corp_Profile is

   function Balanced return Profile is
   begin
      return (Finance_Mult => 1.0, Research_Mult => 1.0,
              Military_Mult => 1.0, Max_Deploy => 6);
   end Balanced;

   function Finance_Heavy return Profile is
   begin
      return (Finance_Mult => 1.75, Research_Mult => 0.85,
              Military_Mult => 0.90, Max_Deploy => 5);
   end Finance_Heavy;

   function Research_Heavy return Profile is
   begin
      return (Finance_Mult => 0.90, Research_Mult => 1.80,
              Military_Mult => 0.95, Max_Deploy => 5);
   end Research_Heavy;

   function Military_Heavy return Profile is
   begin
      return (Finance_Mult => 0.85, Research_Mult => 0.90,
              Military_Mult => 1.70, Max_Deploy => 8);
   end Military_Heavy;

   function Can_Deploy (P : Profile; Units : Natural) return Boolean is
   begin
      return Units <= Natural (P.Max_Deploy);
   end Can_Deploy;

end Corp_Profile;
