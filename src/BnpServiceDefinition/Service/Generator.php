<?php

namespace BnpServiceDefinition\Service;

use BnpServiceDefinition\Definition\ClassDefinition;
use BnpServiceDefinition\Definition\DefinitionRepository;
use BnpServiceDefinition\Definition\MethodCallDefinition;
use BnpServiceDefinition\Dsl\Language;
use BnpServiceDefinition\Options\DefinitionOptions;
use BnpServiceDefinition\Service\ParameterResolver;
use Zend\Code\Generator\ClassGenerator;
use Zend\Code\Generator\DocBlock\Tag\ParamTag;
use Zend\Code\Generator\DocBlock\Tag\ReturnTag;
use Zend\Code\Generator\DocBlockGenerator;
use Zend\Code\Generator\FileGenerator;
use Zend\Code\Generator\MethodGenerator;
use Zend\Code\Generator\ParameterGenerator;
use Zend\Code\Generator\PropertyGenerator;

class Generator
{
    /**
     * @var DefinitionOptions
     */
    protected $options;

    /**
     * @var \BnpServiceDefinition\Service\ParameterResolver
     */
    protected $parameterResolver;

    /**
     * @var Language
     */
    protected $language;

    /**
     * @var array
     */
    protected $immutableRegisteredMethods = array('canCreateServiceWithName', 'createServiceWithName');

    /**
     * @var array
     */
    protected $definitionFactoryMethods = array();

    public function __construct(Language $language, ParameterResolver $parameterResolver, DefinitionOptions $options)
    {
        $this->options = $options;
        $this->parameterResolver = $parameterResolver;
        $this->language = $language;
    }

    public function generate(DefinitionRepository $repository, $filename = null)
    {
        $classFile = new FileGenerator();
        $classFile->setClass($this->generateAbstractFactoryClass($repository));

        if (null !== $filename) {
            $classFile->setFilename($filename);
        }

        return $classFile;
    }

    protected function generateAbstractFactoryClass(DefinitionRepository $repository)
    {
        $class = ClassGenerator::fromArray(array(
            'name' => sprintf('BnpGeneratedAbstractFactory_%s', $repository->getChecksum()),
            'implemented_interfaces' => array(
                'Zend\ServiceManager\AbstractFactoryInterface',
                'Zend\ServiceManager\ServiceLocatorAwareInterface'
            ),
            'properties' => array(
                PropertyGenerator::fromArray(array(
                    'name' => 'services',
                    'visibility' => 'protected',
                    'docblock' => array(
                        'tags' => array(
                            array(
                                'name' => 'var',
                                'content' => 'Zend\ServiceManager\ServiceLocatorInterface'
                            )
                        )
                    )
                )),
                PropertyGenerator::fromArray(array(
                    'name' => 'scopeLocatorName',
                    'visibility' => 'protected',
                    'docblock' => array(
                        'tags' => array(
                            array(
                                'name' => 'var',
                                'content' => 'string'
                            )
                        )
                    )
                ))
            ),
            'methods' => array(
                MethodGenerator::fromArray(array(
                    'name' => '__construct',
                    'parameters' => array(
                        ParameterGenerator::fromArray(array(
                            'name' => 'scopeLocatorName',
                            'default_value' => null
                        ))
                    ),
                    'docblock' => array(
                        'short_description' => 'Constructor',
                        'tags' => array(
                            new ParamTag('scopeLocatorName', array('string'))
                        )
                    ),
                    'body' => '$this->scopeLocatorName = $scopeLocatorName;'
                )),
                MethodGenerator::fromArray(array(
                    'name' => 'canCreateServiceWithName',
                    'parameters' => array(
                        ParameterGenerator::fromArray(array(
                            'name' => 'serviceLocator',
                            'type' => 'Zend\ServiceManager\ServiceLocatorInterface'
                        )),
                        'name',
                        'requestedName',
                    ),
                    'docblock' => array(
                        'short_description' => 'Determine if we can create a service with name',
                        'tags' => array(
                            new ParamTag(
                                'serviceLocatorInterface',
                                array('Zend\ServiceManager\ServiceLocatorInterface')
                            ),
                            new ParamTag(
                                'name',
                                array('string')
                            ),
                            new ParamTag(
                                'requestedName',
                                array('string')
                            ),
                            array(
                                'name' => 'return',
                                'content' => 'bool'
                            )
                        )
                    ),
                    'body' => $this->getCanCreateMethodBody($repository)
                )),
                MethodGenerator::fromArray(array(
                    'name' => 'createServiceWithName',
                    'parameters' => array(
                        ParameterGenerator::fromArray(array(
                            'name' => 'serviceLocator',
                            'type' => 'Zend\ServiceManager\ServiceLocatorInterface'
                        )),
                        'name',
                        'requestedName',
                    ),
                    'docblock' => array(
                        'short_description' => 'Create service with name',
                        'tags' => array(
                            new ParamTag(
                                'serviceLocatorInterface',
                                array('Zend\ServiceManager\ServiceLocatorInterface')
                            ),
                            new ParamTag(
                                'name',
                                array('string')
                            ),
                            new ParamTag(
                                'requestedName',
                                array('string')
                            ),
                            array(
                                'name' => 'return',
                                'content' => 'mixed'
                            )
                        )
                    ),
                    'body' => $this->getCreateMethodBody($repository)
                )),
                MethodGenerator::fromArray(array(
                    'name' => 'setServiceLocator',
                    'parameters' => array(
                        ParameterGenerator::fromArray(array(
                            'name' => 'serviceLocator',
                            'type' => 'Zend\ServiceManager\ServiceLocatorInterface'
                        ))
                    ),
                    'docblock' => array(
                        'short_description' => 'Set service locator',
                        'tags' => array(
                            new ParamTag(
                                'serviceLocator',
                                array('Zend\ServiceManager\ServiceLocatorInterface')
                            )
                        )
                    ),
                    'body' => '$this->services = $serviceLocator;'
                )),
                MethodGenerator::fromArray(array(
                    'name' => 'getServiceLocator',
                    'docblock' => array(
                        'short_description' => 'Get service locator',
                        'tags' => array(
                            array(
                                'name' => 'return',
                                'content' => 'Zend\ServiceManager\ServiceLocatorInterface'
                            )
                        )
                    ),
                    'body' => 'return $this->services;'
                ))
            )
        ));

        $class->addMethods($this->definitionFactoryMethods);
        $this->definitionFactoryMethods = array();

        return $class;
    }

    protected function addDefinitionFactoryMethod(&$definitionName, ClassDefinition $definition)
    {
        $name = $definitionName;

        $definitionName = 'get' . ucfirst($this->getDefinitionCanonicalName($definitionName));
        $i = 0;
        while (
            array_key_exists($definitionName, $this->immutableRegisteredMethods)
            ||
            array_key_exists($definitionName, $this->definitionFactoryMethods)
        ) {
            $definitionName .= ++$i;
        }

        $this->definitionFactoryMethods[$definitionName] = MethodGenerator::fromArray(array(
            'name' => $definitionName,
            'parameters' => array(
                ParameterGenerator::fromArray(array(
                    'name' => 'definitionName',
                    'type' => 'string'
                ))
            ),
            'visibility' => 'protected',
            'docblock' => array(
                'short_description' => sprintf('Returns the service registered under "%s" definition', $name),
                'tags' => array(
                    new ParamTag(
                        'name',
                        array('string')
                    ),
                    new ReturnTag('object')
                )
            ),
            'body' => $this->getFactoryMethodBody($definition)
        ));
    }

    protected function getDefinitionCanonicalName($name)
    {
        return preg_replace('@[^\w]@', '', $name);
    }

    protected function compileDslPart($rawDsl, array $names = array())
    {
        return $this->language->compile($rawDsl, $names);
    }

    protected function compileParameter($param, array $names = array())
    {
        return $this->compileDslPart($this->parameterResolver->resolveParameter($param), $names);
    }

    protected function compileParameters(array $params = array(), $names = array())
    {
        $self = $this;
        return array_map(
            function ($param) use ($self, $names) { return $this->compileDslPart($param, $names); },
            $this->parameterResolver->resolveParameters($params)
        );
    }

    /**
     * @param DefinitionRepository $repository
     * @return string
     */
    protected function getCanCreateMethodBody(DefinitionRepository $repository)
    {
        $knownDefinitions = implode(
            ', ',
            array_map(
                function ($definitionName) { return "'$definitionName'"; },
                array_keys($repository->getTerminableDefinitions())
            )
        );

        return
<<<TEMPLATE
return in_array(\$requestedName, array($knownDefinitions));
TEMPLATE;
    }

    protected function getCreateMethodBody(DefinitionRepository $repository)
    {
        if (! count($repository->getTerminableDefinitions())) {
            return '';
        }

        $cases = '';
        foreach ($repository as $name => $definition) {
            $canonicalName = $name;
            $this->addDefinitionFactoryMethod($canonicalName, $definition);

            $cases .= "\n" . $this->getCaseStatementBody($name, $canonicalName);
        }

        return
<<<TEMPLATE
    switch (\$requestedName) {
        $cases
    }
TEMPLATE;
    }

    protected function getCaseStatementBody($name, $methodName)
    {
        return
<<<TEMPLATE
    case '$name':
        return \$this->$methodName('$name');
TEMPLATE;
    }

    protected function getFactoryMethodBody(ClassDefinition $definition)
    {
        $methodCalls = '';
        foreach (array_values($definition->getMethodCalls()) as $i => $methodCall) {
            /** @var $methodCall MethodCallDefinition */
            $methodCalls .= "\n" . $this->getFactoryMethodCallBody($methodCall, $i);
        }

        if (! empty($methodCalls)) {
            $methodCalls = "\n$methodCalls\n";
        }

        $arguments = implode(', ', $this->compileParameters($definition->getArguments()));

        return
<<<TEMPLATE
\$serviceClassName = {$this->compileParameter($definition->getClass())};
if (! is_string(\$serviceClassName)) {
    throw new \RuntimeException(sprintf(
        '%s definition class was not resolved to a string',
        \$definitionName
    ));
}
if (! class_exists(\$serviceClassName, true)) {
    throw new \RuntimeException(sprintf(
        '%s definition resolved to the class %s, which does no exit',
        \$definitionName,
        \$serviceClassName
    ));
}
\$serviceReflection = new \ReflectionClass(\$serviceClassName);
\$service = \$serviceReflection->newInstanceArgs(array({$arguments}));
$methodCalls
return \$service;
TEMPLATE;
    }

    protected function getFactoryMethodCallBody(MethodCallDefinition $method, $methodIndex)
    {
        $context = array('service');

        $condition = 'true';
        if (null !== $method->getConditions()) {
            $conditions = implode(
                ' and ',
                $this->parameterResolver->resolveParameters($method->getConditions())
            );
            $condition = $this->compileDslPart($conditions, $context);
        }

        $params = implode(', ', $this->compileParameters($method->getParameters(), $context));

        return
<<<TEMPLATE
if ($condition) {
    \$serviceMethod = {$this->compileParameter($method->getName(), $context)};
    if (! is_string(\$serviceMethod)) {
        throw new \RuntimeException(sprintf(
            'A method call can only be a string, %s provided, as %d method call for the %s service definition',
            gettype(\$serviceMethod),
            $methodIndex,
            \$definitionName
        ));
    } elseif (! method_exists(\$service, \$serviceMethod)) {
        throw new \RuntimeException(sprintf(
            'Requested method "%s::%s" (index %d) does not exists or is not visible for %s service definition',
            get_class(\$service),
            \$serviceMethod,
            $methodIndex,
            \$definitionName
        ));
    }

    call_user_func_array(
        array(\$service, \$serviceMethod),
        array({$params})
    );
}
TEMPLATE;
    }
}