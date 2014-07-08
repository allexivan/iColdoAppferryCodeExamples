<?php

namespace BnpServiceDefinitionTest\Dsl\Extension;

use BnpServiceDefinition\Dsl\Extension\ConfigFunctionProvider;
use BnpServiceDefinition\Dsl\Language;
use BnpServiceDefinition\Options\DefinitionOptions;
use Zend\ServiceManager\Config;
use Zend\ServiceManager\ServiceLocatorInterface;
use Zend\ServiceManager\ServiceManager;

class ConfigFunctionProviderTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @var ServiceManager
     */
    protected $services;

    /**
     * @var Language
     */
    protected $language;

    /**
     * @var DefinitionOptions
     */
    protected $definitionOptions;

    protected function setUp()
    {
        $this->services = new ServiceManager(new Config(array(
            'services' => array(
                'Config' => array(
                )
            ),
        )));

        $definitions = $this->definitionOptions = new DefinitionOptions(array());
        $this->services->setFactory(
            'ConfigFunctionProvider',
            function (ServiceLocatorInterface $services) use ($definitions) {
                $provider = new ConfigFunctionProvider($definitions, 'ConfigFunctionProvider');
                $provider->setServiceLocator($services);

                return $provider;
            }
        );

        $this->language = new Language();
        $this->language->registerExtension('ConfigFunctionProvider');
        $this->language->setServiceManager($this->services);
    }

    protected function overrideConfig(array $config = array())
    {
        $allowOverride = $this->services->getAllowOverride();

        $this->services->setAllowOverride(true);
        $this->services->setService('Config', $config);

        $this->services->setAllowOverride($allowOverride);
    }

    protected function getCompiledCode($part)
    {
        return sprintf('$this->services->get(\'ConfigFunctionProvider\')->getConfigValue(%s)', $part);
    }

    public function testCompilesStringPath()
    {
        $this->assertEquals(
            $this->getCompiledCode('"some_key", true, null'),
            $this->language->compile("config('some_key')")
        );
        $this->assertEquals(
            $this->getCompiledCode('"some_key", false, null'),
            $this->language->compile("config('some_key', false)")
        );
        $this->assertEquals(
            $this->getCompiledCode('"some_key", false, "int"'),
            $this->language->compile("config('some_key', false, 'int')")
        );
    }

    public function testCompilesArrayPath()
    {
        $this->assertEquals(
            $this->getCompiledCode('array(0 => "some_key"), true, null'),
            $this->language->compile("config(['some_key'])")
        );
        $this->assertEquals(
            $this->getCompiledCode('array(0 => "some_key", 1 => "tail"), false, null'),
            $this->language->compile("config(['some_key', 'tail'], false)")
        );
        $this->assertEquals(
            $this->getCompiledCode('array(0 => "some_key", 1 => "escaped\'key"), false, "int"'),
            $this->language->compile("config(['some_key', 'escaped\\'key'], false, 'int')")
        );
    }

    public function testCompilesNestedConfigDefinitions()
    {
        $this->assertEquals(
            $this->getCompiledCode(sprintf('%s, true, null', $this->getCompiledCode('"some_key", true, null'))),
            $this->language->compile("config(config('some_key'))")
        );
        $this->assertEquals(
            $this->getCompiledCode(sprintf(
                'array(0 => %s, 1 => "sub_key"), true, null',
                $this->getCompiledCode('"some_key", false, "string"')
            )),
            $this->language->compile("config([config('some_key', false, 'string'), 'sub_key'])")
        );
    }

    /**
     * @expectedException \RuntimeException
     */
    public function testEvaluationWithoutConfig()
    {
        $this->assertNull($this->language->evaluate("config('not_existing_key')"));
        $this->assertNull($this->language->evaluate("config('not_existing_key', true)"));
        $this->assertNull($this->language->evaluate("config('not_existing_key', true, 'array')"));

        $this->language->evaluate("config('not_existing_key', false)");
    }

    public function testEvaluationWithBasicConfig()
    {
        $this->overrideConfig(array(
            'key1' => array('key2' => 'value1')
        ));

        $this->assertNotNull($this->language->evaluate("config('key1')"));
        $this->assertInternalType('array', $this->language->evaluate("config('key1')"));
        $this->assertArrayHasKey('key2', $this->language->evaluate("config('key1')"));

        $config = $this->language->evaluate("config('key1')");
        $this->assertEquals('value1', $config['key2']);
    }

    public function testEvaluationWithArrayPathNestedConfig()
    {
        $this->overrideConfig(array(
            'key1' => array(
                'key2' => array(
                    'key3' => 'value'
                )
            )
        ));

        $this->assertNotNull($this->language->evaluate("config(['key1'])"));

        $this->assertNull($this->language->evaluate("config(['key1', 'key3'])"));
        $this->assertNull($this->language->evaluate("config(['key1.key3'])"));

        $this->assertInternalType('array', $this->language->evaluate("config(['key1', 'key2'])"));
        $this->assertEquals('value', $this->language->evaluate("config(['key1', 'key2', 'key3'])"));
        $this->assertEquals('value', $this->language->evaluate("config(['key1', 'key2', 'key3'], false, 'string')"));
    }

    public function testEvaluatesNestedConfigDefinitions()
    {
        $this->overrideConfig(array(
            'key1' => array(
                'key2' => array(
                    'key3' => 'value'
                ),
            ),
            'key4' => 'key2',
            'key5' => array('key1', 'key2', 'key3')
        ));

        $this->assertEquals('value', $this->language->evaluate("config(config('key5'))"));
        $this->assertEquals(array('key3' => 'value'), $this->language->evaluate("config(['key1', config('key4')])"));
    }
}