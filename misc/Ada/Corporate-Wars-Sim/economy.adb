package body Economy is

   procedure Recalc_Steady_Income
     (S : in out State; P : Corp_Profile.Profile)
   is
      Raw : constant Float :=
        Float (S.Mines) * Float (Income_Per_Mine) * Float (P.Finance_Mult);
   begin
      S.Steady_Income := Credits (Natural (Raw));
   end Recalc_Steady_Income;

   procedure Set_Research_Budget (S : in out State; Amount : Credits) is
   begin
      S.Research_Budget := Amount;
   end Set_Research_Budget;

   procedure Add_Mission_Reward (S : in out State; Amount : Credits) is
   begin
      S.Mission_Rewards := S.Mission_Rewards + Amount;
      S.Treasury        := S.Treasury + Amount;
   end Add_Mission_Reward;

   function Research_From_Steady_Only (S : State) return Boolean is
   begin
      return S.Research_Budget <= S.Steady_Income;
   end Research_From_Steady_Only;

end Economy;
