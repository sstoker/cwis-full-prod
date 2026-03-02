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

/* __string_template__1b71fe2e65700e1e4d403b659c69f9a1 */
class __TwigTemplate_951f6a52186871956c14538a19d4ab6d extends Template
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
        // line 1
        $context["host"] = Twig\Extension\CoreExtension::first($this->env->getCharset(), Twig\Extension\CoreExtension::split($this->env->getCharset(), Twig\Extension\CoreExtension::replace(Twig\Extension\CoreExtension::first($this->env->getCharset(), $this->extensions['Drupal\Core\Template\TwigExtension']->getUrl("<front>")), ["http:" => "", "https:" => "", "/" => ""]), ":"));
        // line 2
        yield "<a href=\"/oai/request?identifier=oai%3A";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["host"] ?? null), "html", null, true);
        yield "%3Anode-";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["nid"] ?? null), "html", null, true);
        yield "&metadataPrefix=mods&verb=GetRecord\">";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Display MODS Record"));
        yield "</a><br> 
<a href=\"/oai/request?identifier=oai%3A";
        // line 3
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["host"] ?? null), "html", null, true);
        yield "%3Anode-";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, ($context["nid"] ?? null), "html", null, true);
        yield "&metadataPrefix=oai_dc&verb=GetRecord\">";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Display DC Record"));
        yield "</a>";
        $this->env->getExtension('\Drupal\Core\Template\TwigExtension')
            ->checkDeprecations($context, ["nid"]);        yield from [];
    }

    /**
     * @codeCoverageIgnore
     */
    public function getTemplateName(): string
    {
        return "__string_template__1b71fe2e65700e1e4d403b659c69f9a1";
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
        return array (  55 => 3,  46 => 2,  44 => 1,);
    }

    public function getSourceContext(): Source
    {
        return new Source("", "__string_template__1b71fe2e65700e1e4d403b659c69f9a1", "");
    }
    
    public function checkSecurity()
    {
        static $tags = ["set" => 1];
        static $filters = ["first" => 1, "split" => 1, "replace" => 1, "escape" => 2, "t" => 2];
        static $functions = ["url" => 1];

        try {
            $this->sandbox->checkSecurity(
                ['set'],
                ['first', 'split', 'replace', 'escape', 't'],
                ['url'],
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
