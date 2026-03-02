<?php

use Twig\Environment;
use Twig\Error\LoaderError;
use Twig\Error\RuntimeError;
use Twig\Extension\CoreExtension;
use Twig\Extension\SandboxExtension;
use Twig\Markup;
use Twig\Sandbox\SecurityError;
use Twig\Sandbox\SecurityNotAllowedTagError;
use Twig\Sandbox\SecurityNotAllowedFilterError;
use Twig\Sandbox\SecurityNotAllowedFunctionError;
use Twig\Source;
use Twig\Template;
use Twig\TemplateWrapper;

/* modules/contrib/facets/templates/facets-item-list.html.twig */
class __TwigTemplate_fe0a73d24b7cfb60b2a63140f67bc217 extends Template
{
    private Source $source;
    /**
     * @var array<string, Template>
     */
    private array $macros = [];

    public function __construct(Environment $env)
    {
        parent::__construct($env);

        $this->source = $this->getSourceContext();

        $this->parent = false;

        $this->blocks = [
        ];
        $this->sandbox = $this->extensions[SandboxExtension::class];
        $this->checkSecurity();
    }

    protected function doDisplay(array $context, array $blocks = []): iterable
    {
        $macros = $this->macros;
        // line 27
        if (($context["cache_hash"] ?? null)) {
            // line 28
            yield "  <!-- facets cacheable metadata
    hash: ";
            // line 29
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["cache_hash"] ?? null), "html", null, true);
            yield "
  ";
            // line 30
            if (($context["cache_contexts"] ?? null)) {
                // line 31
                yield "    contexts: ";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["cache_contexts"] ?? null), "html", null, true);
            }
            // line 33
            yield "  ";
            if (($context["cache_tags"] ?? null)) {
                // line 34
                yield "    tags: ";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["cache_tags"] ?? null), "html", null, true);
            }
            // line 36
            yield "  ";
            if (($context["cache_max_age"] ?? null)) {
                // line 37
                yield "    max age: ";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["cache_max_age"] ?? null), "html", null, true);
            }
            // line 39
            yield "  -->";
        }
        // line 41
        yield "<div class=\"facets-widget-";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "widget", [], "any", false, false, true, 41), "type", [], "any", false, false, true, 41), "html", null, true);
        yield "\">
  ";
        // line 42
        if (CoreExtension::getAttribute($this->env, $this->source, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "widget", [], "any", false, false, true, 42), "type", [], "any", false, false, true, 42)) {
            // line 43
            $context["attributes"] = CoreExtension::getAttribute($this->env, $this->source, ($context["attributes"] ?? null), "addClass", [("item-list__" . CoreExtension::getAttribute($this->env, $this->source, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "widget", [], "any", false, false, true, 43), "type", [], "any", false, false, true, 43))], "method", false, false, true, 43);
            // line 44
            yield "  ";
        }
        // line 45
        yield "  ";
        if ((($context["items"] ?? null) || ($context["empty"] ?? null))) {
            // line 46
            if ( !Twig\Extension\CoreExtension::testEmpty(($context["title"] ?? null))) {
                // line 47
                yield "<h3>";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["title"] ?? null), "html", null, true);
                yield "</h3>";
            }
            // line 50
            if (($context["items"] ?? null)) {
                // line 51
                yield "<";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["list_type"] ?? null), "html", null, true);
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["attributes"] ?? null), "html", null, true);
                yield ">";
                // line 52
                $context['_parent'] = $context;
                $context['_seq'] = CoreExtension::ensureTraversable(($context["items"] ?? null));
                foreach ($context['_seq'] as $context["_key"] => $context["item"]) {
                    // line 53
                    yield "<li";
                    yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, $context["item"], "attributes", [], "any", false, false, true, 53), "html", null, true);
                    yield ">";
                    yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, $context["item"], "value", [], "any", false, false, true, 53), "html", null, true);
                    yield "</li>";
                }
                $_parent = $context['_parent'];
                unset($context['_seq'], $context['_key'], $context['item'], $context['_parent']);
                $context = array_intersect_key($context, $_parent) + $_parent;
                // line 55
                yield "</";
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["list_type"] ?? null), "html", null, true);
                yield ">";
            } else {
                // line 57
                yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["empty"] ?? null), "html", null, true);
            }
        }
        // line 60
        yield "
";
        // line 61
        if ((CoreExtension::getAttribute($this->env, $this->source, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "widget", [], "any", false, false, true, 61), "type", [], "any", false, false, true, 61) == "dropdown")) {
            // line 62
            yield "  <label id=\"facet_";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "id", [], "any", false, false, true, 62), "html", null, true);
            yield "_label\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Facet"));
            yield " ";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["facet"] ?? null), "label", [], "any", false, false, true, 62), "html", null, true);
            yield "</label>";
        }
        // line 64
        yield "</div>
";
        $this->env->getExtension('\Drupal\Core\Template\TwigExtension')
            ->checkDeprecations($context, ["cache_hash", "cache_contexts", "cache_tags", "cache_max_age", "facet", "items", "empty", "title", "list_type"]);        yield from [];
    }

    /**
     * @codeCoverageIgnore
     */
    public function getTemplateName(): string
    {
        return "modules/contrib/facets/templates/facets-item-list.html.twig";
    }

    /**
     * @codeCoverageIgnore
     */
    public function isTraitable(): bool
    {
        return false;
    }

    /**
     * @codeCoverageIgnore
     */
    public function getDebugInfo(): array
    {
        return array (  142 => 64,  133 => 62,  131 => 61,  128 => 60,  124 => 57,  119 => 55,  109 => 53,  105 => 52,  100 => 51,  98 => 50,  93 => 47,  91 => 46,  88 => 45,  85 => 44,  83 => 43,  81 => 42,  76 => 41,  73 => 39,  69 => 37,  66 => 36,  62 => 34,  59 => 33,  55 => 31,  53 => 30,  49 => 29,  46 => 28,  44 => 27,);
    }

    public function getSourceContext(): Source
    {
        return new Source("", "modules/contrib/facets/templates/facets-item-list.html.twig", "/var/www/drupal/web/modules/contrib/facets/templates/facets-item-list.html.twig");
    }
    
    public function checkSecurity()
    {
        static $tags = ["if" => 27, "set" => 43, "for" => 52];
        static $filters = ["escape" => 29, "t" => 62];
        static $functions = [];

        try {
            $this->sandbox->checkSecurity(
                ['if', 'set', 'for'],
                ['escape', 't'],
                [],
                $this->source
            );
        } catch (SecurityError $e) {
            $e->setSourceContext($this->source);

            if ($e instanceof SecurityNotAllowedTagError && isset($tags[$e->getTagName()])) {
                $e->setTemplateLine($tags[$e->getTagName()]);
            } elseif ($e instanceof SecurityNotAllowedFilterError && isset($filters[$e->getFilterName()])) {
                $e->setTemplateLine($filters[$e->getFilterName()]);
            } elseif ($e instanceof SecurityNotAllowedFunctionError && isset($functions[$e->getFunctionName()])) {
                $e->setTemplateLine($functions[$e->getFunctionName()]);
            }

            throw $e;
        }

    }
}
