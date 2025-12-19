package assistant_coaching.demo.goalchat;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Component;

@Component
public class GoalQuestionBank {

    private final Map<String, List<String>> questionsByGoal;

    public GoalQuestionBank() {
        Map<String, List<String>> map = new LinkedHashMap<>();
        map.put("emergency_fund", List.of(
                "Quel est ton revenu mensuel net approximatif ?",
                "Tes revenus sont-ils stables ou variables ?",
                "Quel est ton budget mensuel moyen pour les dépenses essentielles ?",
                "As-tu déjà une épargne disponible aujourd'hui ? Si oui, combien environ ?",
                "Combien de mois de dépenses aimerais-tu couvrir avec ton matelas de sécurité ?",
                "Combien penses-tu pouvoir mettre de côté chaque mois sans te mettre en difficulté ?"
        ));
        map.put("spending_cut", List.of(
                "Quel est ton revenu mensuel net approximatif ?",
                "As-tu une idée de ton budget mensuel total actuel ?",
                "Quelles sont tes plus grosses dépenses fixes (loyer, transport, abonnements, etc.) ?",
                "As-tu des dépenses variables que tu juges excessives ?",
                "Suis-tu actuellement tes dépenses (application, carnet, rien du tout) ?",
                "Quel est ton objectif principal en réduisant tes dépenses (épargne, confort, remboursement de dette) ?"
        ));
        map.put("debt_repayment", List.of(
                "Quel type de dette souhaites-tu rembourser (crédit, prêt, découvert, autre) ?",
                "Quel est le montant total restant à rembourser ?",
                "Quel est le montant de la mensualité actuelle ?",
                "Connais-tu le taux d'intérêt associé à cette dette ?",
                "As-tu d'autres dettes en parallèle ?",
                "Combien pourrais-tu consacrer chaque mois au remboursement sans déséquilibrer ton budget ?"
        ));
        map.put("target_purchase", List.of(
                "Quel est l'achat que tu souhaites financer ?",
                "Quel est le budget total estimé pour cet achat ?",
                "À quelle date aimerais-tu réaliser cet achat ?",
                "As-tu déjà commencé à épargner pour cet objectif ?",
                "Combien peux-tu mettre de côté chaque mois ?",
                "Cet achat est-il prioritaire ou flexible dans le temps ?"
        ));
        map.put("monthly_budget", List.of(
                "Quel est ton revenu mensuel net ?",
                "As-tu déjà un budget mensuel défini ?",
                "Quelles sont tes dépenses fixes principales ?",
                "As-tu souvent des fins de mois difficiles ?",
                "Épargnes-tu actuellement, même un petit montant ?",
                "Préféres-tu un budget très strict ou plutôt flexible ?"
        ));
        map.put("invest_beginner", List.of(
                "As-tu déjà une épargne de sécurité constituée ?",
                "Quel est le montant que tu serais prêt à investir au départ ?",
                "Sur quelle durée envisages-tu cet investissement (court, moyen, long terme) ?",
                "Quel est ton niveau de tolérance au risque (faible, moyen, élevé) ?",
                "Préfères-tu des placements simples ou es-tu prêt à apprendre progressivement ?",
                "Cet argent est-il totalement distinct de tes dépenses essentielles ?"
        ));
        map.put("other_goal", List.of(
                "Peux-tu me décrire brièvement ton objectif financier ?",
                "Pourquoi cet objectif est-il important pour toi ?",
                "As-tu une échéance ou une contrainte particulière ?",
                "Quel est ton revenu mensuel approximatif ?",
                "As-tu déjà réfléchi à une stratégie pour cet objectif ?"
        ));
        this.questionsByGoal = Collections.unmodifiableMap(map);
    }

    public List<String> questionsFor(String goalId) {
        return questionsByGoal.getOrDefault(goalId, questionsByGoal.get("other_goal"));
    }
}
